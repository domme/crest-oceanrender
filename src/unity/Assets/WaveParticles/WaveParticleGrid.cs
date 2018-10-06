using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class WaveParticleGrid : MonoBehaviour
{
  public int gridIndex;

  public Shader wpShader;
  public Mesh mesh;

  private WaveParticleConstants wpConstants;
  private WpWaveProfile waveProfile;
  private Camera cam;
  private Material wpMaterial;
  private Matrix4x4[] wpTransforms;
  private Vector2[] wpVelocities;
  private int gridSize;
  private int wpLayer;

  private RenderTexture renderTexture;
  
	// Use this for initialization
	void Start ()
  {
    wpConstants = GameObject.FindObjectOfType<WaveParticleConstants>();
    waveProfile = GameObject.FindObjectOfType<WpWaveProfile>();

    wpLayer = LayerMask.NameToLayer("WaveParticles");
    gridSize = wpConstants.WaveParticleGridSize;

    RenderTextureDescriptor rtDesc = new RenderTextureDescriptor();
    rtDesc.autoGenerateMips = false;
    rtDesc.colorFormat = RenderTextureFormat.ARGBFloat;
    rtDesc.dimension = TextureDimension.Tex2D;
    rtDesc.sRGB = false;
    rtDesc.useMipMap = false;
    rtDesc.width = gridSize;
    rtDesc.height = gridSize;
    rtDesc.volumeDepth = 1;
    rtDesc.msaaSamples = 1;
    renderTexture = new RenderTexture(rtDesc);
    renderTexture.wrapMode = TextureWrapMode.Repeat;
    renderTexture.filterMode = FilterMode.Bilinear;
        
    GameObject camObj = new GameObject("Camera");
    camObj.transform.position = gameObject.transform.position + new Vector3(0, 1, 0);
    camObj.transform.parent = gameObject.transform;
    camObj.transform.Rotate(Vector3.right, 90.0f);
    cam = camObj.AddComponent<Camera>();
    cam.targetTexture = renderTexture;
    cam.orthographic = true;
    cam.orthographicSize = gridSize / 2;
    cam.cullingMask = LayerMask.GetMask(new string[] { "WaveParticles" });
    cam.clearFlags = CameraClearFlags.SolidColor;
    cam.backgroundColor = new Color(0, 0, 0, 0);
    cam.allowMSAA = false;
    
    wpMaterial = new Material(wpShader);
    wpMaterial.enableInstancing = true;

    Material combineMat = GameObject.Find("CombinedGrids").GetComponent<MeshRenderer>().sharedMaterial;
    string texName = "_WpGridTex" + (gridIndex + 1);
    combineMat.SetTexture(texName, renderTexture);

    InitParticles();
  }

  void InitParticles()
  {
    wpTransforms = new Matrix4x4[waveProfile.numParticles[gridIndex] * 4];
    wpVelocities = new Vector2[waveProfile.numParticles[gridIndex] * 4];
    for (int i = 0; i < waveProfile.numParticles[gridIndex]; ++i)
    {
      Vector3 pos = new Vector3(
        (Random.value - 0.5f) * (gridSize - 1),
        0.0f,
        (Random.value - 0.5f) * (gridSize - 1)
      );
      //Vector3 pos = Vector3.zero;
      pos += transform.position;

      wpTransforms[i].SetTRS(pos, Quaternion.AngleAxis(90, Vector3.right), Vector3.one * waveProfile.particleSize[gridIndex]);
      wpVelocities[i] = Random.insideUnitCircle * waveProfile.speed[gridIndex];
      // wpVelocities[i] = new Vector2(0.7f, 0.9f).normalized * 5;
    }
  }

  // Update is called once per frame
  void Update ()
  {
    if (waveProfile.needsRecreate[gridIndex])
      InitParticles();

    waveProfile.needsRecreate[gridIndex] = false;

    wpMaterial.SetFloat("_Amplitude", waveProfile.amplitude[gridIndex]);
    wpMaterial.SetFloat("_Choppiness", waveProfile.choppiness[gridIndex]);

    float halfGridSize = (float) gridSize / 2;
    float wpRadius = waveProfile.particleSize[gridIndex] / 2;

    for (int i = 0; i < waveProfile.numParticles[gridIndex]; ++i)
    {
      Vector4 pos = wpTransforms[i].GetColumn(3) - new Vector4(transform.position.x, 0, transform.position.z, 0);

      if (!wpConstants.Pause)
      {
        pos.x += wpVelocities[i].x * Time.deltaTime;
        pos.z += wpVelocities[i].y * Time.deltaTime;
      }

      if (pos.x - wpRadius > halfGridSize)
        pos.x -= gridSize;
      else if (pos.x + wpRadius < -halfGridSize)
        pos.x += gridSize;
      if (pos.z + wpRadius < -halfGridSize)
        pos.z += gridSize;
      else if (pos.z - wpRadius > halfGridSize)
        pos.z -= gridSize;
      
      wpTransforms[i].SetTRS(pos + new Vector4(transform.position.x, 0, transform.position.z, 0), Quaternion.AngleAxis(90, Vector3.right), Vector3.one * waveProfile.particleSize[gridIndex]);
    }

    int numAdditionalParticles = 0;

    for (int i = 0; i < waveProfile.numParticles[gridIndex]; ++i)
    {
      Vector4 pos = wpTransforms[i].GetColumn(3) - new Vector4(transform.position.x, 0, transform.position.z, 0);
    
      // Render additional particles (mirrored)?
      if (pos.x + wpRadius > halfGridSize)
      {
        Vector4 tiledPos = pos - new Vector4(gridSize, 0, 0, 0);
        wpTransforms[waveProfile.numParticles[gridIndex] + numAdditionalParticles].SetTRS(tiledPos + new Vector4(transform.position.x, 0, transform.position.z, 0), Quaternion.AngleAxis(90, Vector3.right), Vector3.one * waveProfile.particleSize[gridIndex]);
        ++numAdditionalParticles;
      }
      else if (pos.x - wpRadius < -halfGridSize)
      {
        Vector4 tiledPos = pos + new Vector4(gridSize, 0, 0, 0);
        wpTransforms[waveProfile.numParticles[gridIndex] + numAdditionalParticles].SetTRS(tiledPos + new Vector4(transform.position.x, 0, transform.position.z, 0), Quaternion.AngleAxis(90, Vector3.right), Vector3.one * waveProfile.particleSize[gridIndex]);
        ++numAdditionalParticles;
      }  
    }

    for (int i = 0, e = waveProfile.numParticles[gridIndex] + numAdditionalParticles; i < e; ++i)
    {
      Vector4 pos = wpTransforms[i].GetColumn(3) - new Vector4(transform.position.x, 0, transform.position.z, 0);

      if (pos.z - wpRadius < -halfGridSize)
      {
        Vector4 tiledPos = pos + new Vector4(0, 0, gridSize, 0);
        wpTransforms[waveProfile.numParticles[gridIndex] + numAdditionalParticles].SetTRS(tiledPos + new Vector4(transform.position.x, 0, transform.position.z, 0), Quaternion.AngleAxis(90, Vector3.right), Vector3.one * waveProfile.particleSize[gridIndex]);
        ++numAdditionalParticles;
      }
      else if (pos.z + wpRadius > halfGridSize)
      {
        Vector4 tiledPos = pos - new Vector4(0, 0, gridSize, 0);
        wpTransforms[waveProfile.numParticles[gridIndex] + numAdditionalParticles].SetTRS(tiledPos + new Vector4(transform.position.x, 0, transform.position.z, 0), Quaternion.AngleAxis(90, Vector3.right), Vector3.one * waveProfile.particleSize[gridIndex]);
        ++numAdditionalParticles;
      }
    }
    
    Graphics.DrawMeshInstanced(mesh, 0, wpMaterial, wpTransforms, waveProfile.numParticles[gridIndex] + numAdditionalParticles, null, ShadowCastingMode.Off, false, wpLayer);
  }
}
