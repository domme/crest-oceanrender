﻿// This file is subject to the MIT License as seen in the root of this folder structure (LICENSE)

using UnityEngine;

namespace Crest
{
    /// <summary>
    /// This collision provider reads back the displacement textures from the GPU. This means all shape is automatically
    /// included and the shape is relatively cheap to read. Be aware however that there is a ~2 frame latency involved for
    /// this collision provider type.
    /// </summary>
    public class CollProviderDispTexs : ICollProvider
    {
        int _areaLod = -1;

        public bool SampleDisplacement(ref Vector3 in__worldPos, out Vector3 displacement)
        {
            int lod = LodDataAnimatedWaves.SuggestDataLOD(new Rect(in__worldPos.x, in__worldPos.z, 0f, 0f), 0f);
            if (lod == -1) {
                displacement = Vector3.zero;
                return false;
            }
            return OceanRenderer.Instance._lodDataAnimWaves[lod].SampleDisplacement(ref in__worldPos, out displacement);
        }
        public bool SampleDisplacement(ref Vector3 in__worldPos, out Vector3 displacement, float minSpatialLength)
        {
            // select lod. this now has a 1 texel buffer, so the finite differences below should all be valid.
            PrewarmForSamplingArea(new Rect(in__worldPos.x, in__worldPos.z, 0f, 0f), minSpatialLength);

            return SampleDisplacementInArea(ref in__worldPos, out displacement);
        }

        public bool SampleHeight(ref Vector3 in__worldPos, out float height)
        {
            int lod = LodDataAnimatedWaves.SuggestDataLOD(new Rect(in__worldPos.x, in__worldPos.z, 0f, 0f), 0f);
            if (lod == -1) {
                height = 0;
                return false;
            }
            height = OceanRenderer.Instance._lodDataAnimWaves[lod].GetHeight(ref in__worldPos);
            return true;
        }

        public void PrewarmForSamplingArea(Rect areaXZ)
        {
            _areaLod = LodDataAnimatedWaves.SuggestDataLOD(areaXZ);
        }
        public void PrewarmForSamplingArea(Rect areaXZ, float minSpatialLength)
        {
            _areaLod = LodDataAnimatedWaves.SuggestDataLOD(areaXZ, minSpatialLength);
        }
        public bool SampleDisplacementInArea(ref Vector3 in__worldPos, out Vector3 displacement)
        {
            return OceanRenderer.Instance._lodDataAnimWaves[_areaLod].SampleDisplacement(ref in__worldPos, out displacement);
        }
        public bool SampleHeightInArea(ref Vector3 in__worldPos, out float height)
        {
            height = OceanRenderer.Instance._lodDataAnimWaves[_areaLod].GetHeight(ref in__worldPos);
            return true;
        }

        public bool SampleNormal(ref Vector3 in__undisplacedWorldPos, out Vector3 normal)
        {
            return SampleNormal(ref in__undisplacedWorldPos, out normal, 0f);
        }
        public bool SampleNormal(ref Vector3 in__undisplacedWorldPos, out Vector3 normal, float minSpatialLength)
        {
            // select lod. this now has a 1 texel buffer, so the finite differences below should all be valid.
            PrewarmForSamplingArea(new Rect(in__undisplacedWorldPos.x, in__undisplacedWorldPos.z, 0f, 0f), minSpatialLength);

            float gridSize = OceanRenderer.Instance._lodDataAnimWaves[_areaLod].LodTransform._renderData._texelWidth;
            normal = Vector3.zero;
            Vector3 dispCenter = Vector3.zero;
            if (!SampleDisplacementInArea(ref in__undisplacedWorldPos, out dispCenter)) return false;
            Vector3 undisplacedWorldPosX = in__undisplacedWorldPos + Vector3.right * gridSize;
            Vector3 dispX = Vector3.zero;
            if (!SampleDisplacementInArea(ref undisplacedWorldPosX, out dispX)) return false;
            Vector3 undisplacedWorldPosZ = in__undisplacedWorldPos + Vector3.forward * gridSize;
            Vector3 dispZ = Vector3.zero;
            if (!SampleDisplacementInArea(ref undisplacedWorldPosZ, out dispZ)) return false;

            normal = Vector3.Cross(dispZ + Vector3.forward * gridSize - dispCenter, dispX + Vector3.right * gridSize - dispCenter).normalized;

            return true;
        }

        public bool ComputeUndisplacedPosition(ref Vector3 in__worldPos, out Vector3 undisplacedWorldPos)
        {
            // fpi - guess should converge to location that displaces to the target position
            Vector3 guess = in__worldPos;
            // 2 iterations was enough to get very close when chop = 1, added 2 more which should be
            // sufficient for most applications. for high chop values or really stormy conditions there may
            // be some error here. one could also terminate iteration based on the size of the error, this is
            // worth trying but is left as future work for now.
            Vector3 disp = Vector3.zero;
            for (int i = 0; i < 4 && SampleDisplacement(ref guess, out disp); i++)
            {
                Vector3 error = guess + disp - in__worldPos;
                guess.x -= error.x;
                guess.z -= error.z;
            }

            undisplacedWorldPos = guess;
            undisplacedWorldPos.y = OceanRenderer.Instance.SeaLevel;

            return true;
        }
    }
}
