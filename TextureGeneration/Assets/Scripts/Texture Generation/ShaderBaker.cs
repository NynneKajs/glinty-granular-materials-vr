using UnityEngine;
using System.Collections;
using System.IO;
using System.Threading;
using UnityEditor;

// Overall approach of this script was made based on 
// the scripts by sneha belkhale from https://github.com/sneha-belkhale/shader-bake-unity
public class ShaderBaker : MonoBehaviour
{
    public GameObject objectToBake;
    public Material uvMaterial;
    public Material[] sandMaterials;
    public Vector2Int textureDim;
    public Texture2D colorTexture;
    public string dstFolderPath;

    private bool capture;
    private string[] fileNames = { "_SlopeTex", "_ColorTex", "_GlintTex"};

    void Start()
    {
        capture = false;
    }

    void Update()
    {
        capture = false;
        if (Input.GetKeyDown(KeyCode.Space))
        {
            Debug.Log("Generating new sand texture...");
            capture = true; 
        }
    }

    public void OnPostRender()
    {
        if(capture)
        {
            BakeTextures();
        }
    }

    void BakeTextures()
    {
        uvMaterial.SetFloat("_ENABLE_UVVIEW", 1);
        for (int i = 0; i < 3; i++)
        {
            BakeTexture(i, fileNames[i]);
        }

        BakeTexture(1, "LowResColors");
        setAverageColor();

        uvMaterial.SetFloat("_ENABLE_UVVIEW", 0);
        uvMaterial.SetInt("_OutputType", 4);
    }

    // PropertyValue = {0: normals; 1: colors; 2: glints}
    private void BakeTexture(int propertyValue, string fileName)  
    {
        uvMaterial.SetInt("_OutputType", propertyValue);
        RenderTexture rt;
        if (fileName == "LowResColors")
            rt = RenderTexture.GetTemporary(64,64); 
        else
            rt = RenderTexture.GetTemporary(textureDim.x, textureDim.y);
        Mesh M = objectToBake.GetComponent<MeshFilter>().mesh;

        Graphics.SetRenderTarget(rt);
        GL.PushMatrix();
        GL.LoadOrtho();
        uvMaterial.SetPass(0);
        Graphics.DrawMeshNow(M, Matrix4x4.identity);
        Graphics.SetRenderTarget(null);
        SaveRenderTexture(rt, fileName);
        RenderTexture.ReleaseTemporary(rt);
        GL.PopMatrix();
    }

    private Color getAverageColor()
    {
        Color[] pixels = colorTexture.GetPixels();
        Color averageCol = new Color(0,0,0,1);
        for(int i = 0; i < pixels.Length; i++)
        {
            averageCol += (pixels[i] / pixels.Length);
        }
        averageCol.a = 1;
        return averageCol;
    }

    private void setAverageColor()
    {
        Color avg = getAverageColor();
        Texture2D averageColorTex = new Texture2D(1, 1);
        averageColorTex.SetPixel(0, 0, avg);
        SaveTexture(averageColorTex, "_AverageColorTex");
        uvMaterial.SetColor("_AverageColor", avg);
    }

    private void SaveTexture(Texture2D tex, string fileName)
    {
        string fullPath = Application.dataPath + dstFolderPath + fileName + ".png";
        byte[] _bytes = tex.EncodeToPNG();
        File.Delete(fullPath);
        File.WriteAllBytes(fullPath, _bytes);
        #if UNITY_EDITOR
                AssetDatabase.Refresh();
        #endif
    }

    private void SaveRenderTexture(RenderTexture rt, string fileName)
    {
        string fullPath = Application.dataPath + dstFolderPath + fileName + ".png";
        Texture2D tex = toTexture2D(rt);
        byte[] _bytes = tex.EncodeToPNG();
        File.Delete(fullPath);
        File.WriteAllBytes(fullPath, _bytes);
        #if UNITY_EDITOR
            AssetDatabase.Refresh();
        #endif
    }
    Texture2D toTexture2D(RenderTexture rTex)
    {
        Texture2D tex = new Texture2D(rTex.width, rTex.height, TextureFormat.RGB24, false);
        RenderTexture.active = rTex;
        tex.ReadPixels(new Rect(0, 0, rTex.width, rTex.height), 0, 0);
        tex.Apply();
        return tex;
    }
}