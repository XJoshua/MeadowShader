using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EditorTerrainCreate : MonoBehaviour
{
    public int TerrainSize = 100;
    public Material TerrainMat;
    public Material GrassMat;
    public Material FlowerMat;

    public Texture2D HeightMap;
    public float HeightScale;

    public int Mount = 5; // ??

    public bool ShowTerrain;
    public bool ShowGrass;
    public bool ShowFlower;

    private float baseHeight;

    public GameObject TargetBall;

    void Start()
    {
        baseHeight = TerrainSize * 0.05f;

        if(ShowTerrain)
            CreateTerrain();
        
        if(ShowGrass)
            CreateGrass();

        if(ShowFlower)
            CreateFlower();
    }

    void Update()
    {
        SetTargetPos();
    }

    public void CreateTerrain()
    {
        List<Vector3> verts = new List<Vector3>();
        List<int> tris = new List<int>();

        // 注意网格上限是65000，边长超过254就会无法生成了
        // 边长超过250就计算实际长度
        int count = this.TerrainSize;
        float dis = 1f;
        if (count > 250)
        {
            dis = count / 250;
            count = 250;
        }

        for (int i = 0; i < count; i++)
        {
            for (int j = 0; j < count; j++)
            {
                //Debug.Log(HeightMap.GetPixel(i, j).grayscale * HeightScale);
                verts.Add(new Vector3(i * dis, HeightMap.GetPixel(i * 5, j * 5).grayscale * HeightScale * baseHeight, j * dis));
                if (i == 0 || j == 0)
                    continue;
                tris.Add(count * i + j);
                tris.Add(count * i + j - 1);
                tris.Add(count * (i - 1) + j - 1);
                tris.Add(count * (i - 1) + j - 1);
                tris.Add(count * (i - 1) + j);
                tris.Add(count * i + j);
            }
        }

        Vector2[] uvs = new Vector2[verts.Count];

        for (var i = 0; i < uvs.Length; i++)
        {
            uvs[i] = new Vector2(verts[i].x / count, verts[i].z / count);
        }

        GameObject plane = new GameObject("Ground");
        plane.AddComponent<MeshFilter>();
        MeshRenderer renderer = plane.AddComponent<MeshRenderer>();
        
        renderer.sharedMaterial = TerrainMat;

        Mesh groundMesh = new Mesh();
        groundMesh.vertices = verts.ToArray();
        groundMesh.uv = uvs;
        //groundMesh.uv2 = uvs;
        groundMesh.triangles = tris.ToArray();
        groundMesh.RecalculateNormals();
        plane.GetComponent<MeshFilter>().mesh = groundMesh;

        plane.AddComponent<MeshCollider>();
    }

    public void CreateGrass()
    {
        GameObject grassField = new GameObject("GrassMeadow");
        MeshFilter mf = grassField.AddComponent<MeshFilter>();
        Mesh mesh = new Mesh();
        MeshRenderer mr = grassField.AddComponent<MeshRenderer>();
        mr.sharedMaterial = GrassMat;
        List<int> indices = new List<int>();
        List<Vector3> verts = new List<Vector3>();
        int p = 0;
        for (int i = 0; i < this.TerrainSize; i++)
        {
            for (int j = 0; j < this.TerrainSize; j++)
            {
                float density = HeightMap.GetPixel(i * 10, j * 10).r;
                if (density <= 0.3f) continue;

                int mount = (int)(UnityEngine.Random.Range(0, density) * 8) - 1;
                if (mount <= 0) continue;
                //int mount = 4;
                for (int z = 0; z < Mount; z++)
                {
                    verts.Add(new Vector3(i + Random.Range(-1f, 1f), 
                        HeightMap.GetPixel(i * 5, j * 5).grayscale * HeightScale * baseHeight, j + Random.Range(-1f, 1f)));
                    indices.Add(p);
                    p++;
                }
            }
        }

        Vector2[] uvs = new Vector2[verts.Count];

        for (var i = 0; i < uvs.Length; i++)
        {
            uvs[i] = new Vector2(verts[i].x / TerrainSize, verts[i].z / TerrainSize);
        }

        mesh.vertices = verts.ToArray();
        mesh.uv = uvs;
        mesh.SetIndices(indices.GetRange(0, verts.Count).ToArray(), MeshTopology.Points, 0);
        mf.mesh = mesh;
    }

    public void CreateFlower()
    {
        GameObject grassField = new GameObject("FlowerMeadow");
        MeshFilter mf = grassField.AddComponent<MeshFilter>();
        Mesh mesh = new Mesh();
        MeshRenderer mr = grassField.AddComponent<MeshRenderer>();
        mr.sharedMaterial = FlowerMat;
        List<int> indices = new List<int>();
        List<Vector3> verts = new List<Vector3>();
        int p = 0;
        for (int i = 0; i < this.TerrainSize; i++)
        {
            for (int j = 0; j < this.TerrainSize; j++)
            {
                float density = HeightMap.GetPixel(i * 5, j * 5).r;
                if (density <= 0.4f) continue;

                int mount = (int)((UnityEngine.Random.Range(0, density) * 4) - 1f);
                if (mount <= 0) continue;

                for (int z = 0; z < Mount; z++)
                {
                    verts.Add(new Vector3(i + Random.Range(-1f, 1f),
                        HeightMap.GetPixel(i * 5, j * 5).grayscale * HeightScale * baseHeight, j + Random.Range(-1f, 1f)));
                    indices.Add(p);
                    p++;
                }
            }
        }

        Vector2[] uvs = new Vector2[verts.Count];

        for (var i = 0; i < uvs.Length; i++)
        {
            uvs[i] = new Vector2(verts[i].x / TerrainSize, verts[i].z / TerrainSize);
        }

        mesh.vertices = verts.ToArray();
        mesh.uv = uvs;
        mesh.SetIndices(indices.GetRange(0, verts.Count).ToArray(), MeshTopology.Points, 0);
        mf.mesh = mesh;
    }

    public void SetTargetPos()
    {
        Vector3 pos = TargetBall.transform.position;

       // Vector2 uvPos = new Vector2(pos.x / 200f, pos.y / 200f);

        GrassMat.SetVector("_TargetPos", pos);
        FlowerMat.SetVector("_TargetPos", pos);
    }

}
