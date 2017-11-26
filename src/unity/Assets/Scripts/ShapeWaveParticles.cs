using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShapeWaveParticles : MonoBehaviour
{
  [Range(0.1f, 50.0f)]
  public float BaseGridScale = 1.0f;
  
  public Mesh QuadMesh;
  public Material material;

  private WaveParticleConstants wpConstants;
  
  // Use this for initialization
  void Start ()
  {
    wpConstants = GameObject.FindObjectOfType<WaveParticleConstants>();

    GameObject GO = new GameObject("WaveParticleGrid 0");
    GO.layer = gameObject.layer;

    MeshFilter meshFilter = GO.AddComponent<MeshFilter>();
    meshFilter.mesh = QuadMesh;

    GO.transform.parent = transform;
    GO.transform.localPosition = Vector3.zero;
    GO.transform.localRotation = Quaternion.identity;
    GO.transform.localScale = Vector3.one;

    MeshRenderer renderer = GO.AddComponent<MeshRenderer>();
    renderer.sharedMaterial = material;
  }
	
	void Update ()
  {
    material.SetFloat("_BaseGridSize", wpConstants.WaveParticleGridSize * BaseGridScale);
	}
}
