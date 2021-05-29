using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class MeshPostProcess : AssetPostprocessor
{
	void OnPostprocessModel (GameObject gameObject)
	{
		var meshFilter = gameObject.GetComponent<MeshFilter>();
		var importedMesh = meshFilter.sharedMesh;

		List<Vector3> verticesList = new List<Vector3>(importedMesh.vertexCount);
		importedMesh.GetVertices(verticesList);

		// Inject copy of vertex array in to second UV channel. This array would not be modified during batching, and we can use it get vertex batching offset.
		importedMesh.SetUVs(1, verticesList);
	}
}