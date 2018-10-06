using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class WaveParticleGrid : MonoBehaviour
{
  public float velocity = 5.0f;
  public float choppiness = 1.0f;
  public float amplitude = 1.0f;

  public Shader wpShader;
  public RenderTexture wpGridTex;
  public Mesh mesh;

  private WaveParticleConstants wpConstants;
  private Camera cam;
  private Material wpMaterial;
  private Matrix4x4[] wpTransforms;
  private Vector2[] wpVelocities;
  private int gridSize;
  private int wpLayer;
  
	// Use this for initialization
	void Start ()
  {
    wpConstants = GameObject.FindObjectOfType<WaveParticleConstants>();

    wpLayer = LayerMask.NameToLayer("WaveParticles");
    gridSize = wpConstants.WaveParticleGridSize;

    GameObject camObj = new GameObject("Camera");
    camObj.transform.position = gameObject.transform.position + new Vector3(0, 1, 0);
    camObj.transform.parent = gameObject.transform;
    camObj.transform.Rotate(Vector3.right, 90.0f);

    cam = camObj.AddComponent<Camera>();
    cam.targetTexture = wpGridTex;
    cam.orthographic = true;
    cam.orthographicSize = gridSize / 2;
    cam.cullingMask = LayerMask.GetMask(new string[] { "WaveParticles" });
    cam.clearFlags = CameraClearFlags.SolidColor;
    cam.backgroundColor = new Color(0, 0, 0, 0);
    cam.allowMSAA = false;

    gameObject.isStatic = true;

    wpMaterial = new Material(wpShader);
    wpMaterial.enableInstancing = true;

    InitParticles();
  }

  private int _lastNumParticles;
  private float _lastVelocity;
  void InitParticles()
  {
    wpTransforms = new Matrix4x4[wpConstants.NumParticlesPerGrid * 4];
    wpVelocities = new Vector2[wpConstants.NumParticlesPerGrid * 4];
    for (int i = 0; i < wpConstants.NumParticlesPerGrid; ++i)
    {
      Vector3 pos = new Vector3(
        (Random.value - 0.5f) * (gridSize - 1),
        0.0f,
        (Random.value - 0.5f) * (gridSize - 1)
      );
      //Vector3 pos = Vector3.zero;
      pos += transform.position;

      wpTransforms[i].SetTRS(pos, Quaternion.AngleAxis(90, Vector3.right), Vector3.one * wpConstants.WaveParticleSize);
      wpVelocities[i] = Random.insideUnitCircle * velocity;
      // wpVelocities[i] = new Vector2(0.7f, 0.9f).normalized * 5;
    }

    _lastNumParticles = wpConstants.NumParticlesPerGrid;
    _lastVelocity = velocity;
  }

  // Update is called once per frame
  void Update ()
  {
    if (_lastNumParticles != wpConstants.NumParticlesPerGrid || !Mathf.Approximately(_lastVelocity, velocity))
      InitParticles();

    float particleSize = wpConstants.WaveParticleSize;
    int numParticles = wpConstants.NumParticlesPerGrid;

    wpMaterial.SetFloat("_Amplitude", amplitude);
    wpMaterial.SetFloat("_Radius", particleSize);
    wpMaterial.SetFloat("_Choppiness", choppiness);

    float halfGridSize = (float) gridSize / 2;
    float wpRadius = particleSize / 2;

    for (int i = 0; i < numParticles; ++i)
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
      
      wpTransforms[i].SetTRS(pos + new Vector4(transform.position.x, 0, transform.position.z, 0), Quaternion.AngleAxis(90, Vector3.right), Vector3.one * particleSize);
    }

    int numAdditionalParticles = 0;

    for (int i = 0; i < numParticles; ++i)
    {
      Vector4 pos = wpTransforms[i].GetColumn(3) - new Vector4(transform.position.x, 0, transform.position.z, 0);
    
      // Render additional particles (mirrored)?
      if (pos.x + wpRadius > halfGridSize)
      {
        Vector4 tiledPos = pos - new Vector4(gridSize, 0, 0, 0);
        wpTransforms[numParticles + numAdditionalParticles].SetTRS(tiledPos + new Vector4(transform.position.x, 0, transform.position.z, 0), Quaternion.AngleAxis(90, Vector3.right), Vector3.one * particleSize);
        ++numAdditionalParticles;
      }
      else if (pos.x - wpRadius < -halfGridSize)
      {
        Vector4 tiledPos = pos + new Vector4(gridSize, 0, 0, 0);
        wpTransforms[numParticles + numAdditionalParticles].SetTRS(tiledPos + new Vector4(transform.position.x, 0, transform.position.z, 0), Quaternion.AngleAxis(90, Vector3.right), Vector3.one * particleSize);
        ++numAdditionalParticles;
      }  
    }

    for (int i = 0, e = numParticles + numAdditionalParticles; i < e; ++i)
    {
      Vector4 pos = wpTransforms[i].GetColumn(3) - new Vector4(transform.position.x, 0, transform.position.z, 0);

      if (pos.z - wpRadius < -halfGridSize)
      {
        Vector4 tiledPos = pos + new Vector4(0, 0, gridSize, 0);
        wpTransforms[numParticles + numAdditionalParticles].SetTRS(tiledPos + new Vector4(transform.position.x, 0, transform.position.z, 0), Quaternion.AngleAxis(90, Vector3.right), Vector3.one * particleSize);
        ++numAdditionalParticles;
      }
      else if (pos.z + wpRadius > halfGridSize)
      {
        Vector4 tiledPos = pos - new Vector4(0, 0, gridSize, 0);
        wpTransforms[numParticles + numAdditionalParticles].SetTRS(tiledPos + new Vector4(transform.position.x, 0, transform.position.z, 0), Quaternion.AngleAxis(90, Vector3.right), Vector3.one * particleSize);
        ++numAdditionalParticles;
      }
    }
    
    Graphics.DrawMeshInstanced(mesh, 0, wpMaterial, wpTransforms, numParticles + numAdditionalParticles, null, ShadowCastingMode.Off, false, wpLayer);
  }
}
