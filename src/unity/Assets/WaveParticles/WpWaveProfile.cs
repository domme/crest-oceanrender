using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WpWaveProfile : MonoBehaviour
{
  public int numParticles1 = 300;
  public float particleSize1 = 5.0f;
  public float amplitude1 = 1.0f;
  public float choppiness1 = 0.1f;
  public float speed1 = 5.0f;
  public Vector2 gridScale1 = new Vector2(1.0f, 1.0f);

  [Space(10)]
  public int numParticles2 = 300;
  public float particleSize2 = 5.0f;
  public float amplitude2 = 1.0f;
  public float choppiness2 = 0.1f;
  public float speed2 = 5.0f;
  public Vector2 gridScale2 = new Vector2(1.0f, 1.0f);

  [Space(10)]
  public int numParticles3 = 300;
  public float particleSize3 = 5.0f;
  public float amplitude3 = 1.0f;
  public float choppiness3 = 0.1f;
  public float speed3 = 5.0f;
  public Vector2 gridScale3 = new Vector2(1.0f, 1.0f);

  [Space(10)]
  public int numParticles4 = 300;
  public float particleSize4 = 5.0f;
  public float amplitude4 = 1.0f;
  public float choppiness4 = 0.1f;
  public float speed4 = 5.0f;
  public Vector2 gridScale4 = new Vector2(1.0f, 1.0f);

  [HideInInspector]
  public int[] numParticles = new int[4];
  [HideInInspector]
  public float[] particleSize = new float[4];
  [HideInInspector]
  public float[] amplitude = new float[4];
  [HideInInspector]
  public float[] choppiness = new float[4];
  [HideInInspector]
  public float[] speed = new float[4];
  [HideInInspector]
  public Vector2[] gridScale = new Vector2[4];
  [HideInInspector]
  public bool[] needsRecreate = new bool[4];

  private Material gridCombineMat;

  private void CopyValues()
  {
    needsRecreate[0] = numParticles[0] != numParticles1 || speed[0] != speed1;
    needsRecreate[1] = numParticles[1] != numParticles2 || speed[1] != speed2;
    needsRecreate[2] = numParticles[2] != numParticles3 || speed[2] != speed3;
    needsRecreate[3] = numParticles[3] != numParticles4 || speed[3] != speed4;

    numParticles[0] = numParticles1;
    numParticles[1] = numParticles2;
    numParticles[2] = numParticles3;
    numParticles[3] = numParticles4;

    particleSize[0] = particleSize1;
    particleSize[1] = particleSize2;
    particleSize[2] = particleSize3;
    particleSize[3] = particleSize4;

    amplitude[0] = amplitude1;
    amplitude[1] = amplitude2;
    amplitude[2] = amplitude3;
    amplitude[3] = amplitude4;

    choppiness[0] = choppiness1;
    choppiness[1] = choppiness2;
    choppiness[2] = choppiness3;
    choppiness[3] = choppiness4;

    speed[0] = speed1;
    speed[1] = speed2;
    speed[2] = speed3;
    speed[3] = speed4;

    gridScale[0] = gridScale1;
    gridScale[1] = gridScale2;
    gridScale[2] = gridScale3;
    gridScale[3] = gridScale4;
  }

  void Start()
  {
    CopyValues();

    MeshRenderer mr = GameObject.Find("CombinedGrids").GetComponent<MeshRenderer>();
    gridCombineMat = mr.sharedMaterial;
  }

  private void Update()
  {
    CopyValues();

    if (gridCombineMat != null)
    {
      gridCombineMat.SetTextureScale("_WpGridTex1", gridScale1);
      gridCombineMat.SetTextureScale("_WpGridTex2", gridScale2);
      gridCombineMat.SetTextureScale("_WpGridTex3", gridScale3);
      gridCombineMat.SetTextureScale("_WpGridTex4", gridScale4);
    }
  }
}