using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Mix : MonoBehaviour
{
    #region Variables
    public Shader curShader;
    public Texture2D blendTexture;
    public float blendOpacity = 1.0f;
    public float depthPower = 0.2f;
    public float blendStart = 0.2f; // 控制从哪里开始混合

    // 新增 BSC 控制参数
    [Header ("BSC 调节")]
    public float brightness = 1.0f;
    public float saturation = 1.0f;
    public float contrast = 1.0f;

    private Material screenMat;
    #endregion

    #region Properties
    Material ScreenMat
    {
        get
        {
            if (screenMat == null)
            {
                screenMat = new Material(curShader);
                screenMat.hideFlags = HideFlags.HideAndDontSave;
            }
            return screenMat;
        }
    }
    #endregion

    void Start()
    {
        // 【唯一修改点】给挂载脚本自己这个相机开启深度，不再找Camera.main
        Camera cam = GetComponent<Camera>();
        if(cam != null)
        {
            cam.depthTextureMode = DepthTextureMode.Depth;
        }

        if (!curShader || !curShader.isSupported)
        {
            enabled = false;
        }
    }

    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
    {
        if (curShader != null)
        {
            ScreenMat.SetTexture("_BlendTex", blendTexture);
            ScreenMat.SetFloat("_Opacity", blendOpacity);
            ScreenMat.SetFloat("_DepthPower", depthPower);
            ScreenMat.SetFloat("_BlendStart", blendStart);

            // 传递 BSC 参数到 Shader
            ScreenMat.SetFloat ("_Brightness", brightness);
            ScreenMat.SetFloat ("_Saturation", saturation);
            ScreenMat.SetFloat ("_Contrast", contrast);

            Graphics.Blit(sourceTexture, destTexture, ScreenMat);
        }
        else
        {
            Graphics.Blit(sourceTexture, destTexture);
        }
    }

    void Update()
    {
        // ========= 删除了原来这里的 Camera.main.depthTextureMode 这一行！这就是元凶 =========
        blendOpacity = Mathf.Clamp01(blendOpacity);
        depthPower = Mathf.Clamp(depthPower, 0.0f, 0.5f);
        blendStart = Mathf.Clamp01(blendStart);

        // BSC 参数范围限制
        brightness = Mathf.Clamp (brightness, 0, 2);
        saturation = Mathf.Clamp (saturation, 0, 2);
        contrast = Mathf.Clamp (contrast, 0, 2);
    }

    void OnDisable()
    {
        if (screenMat)
        {
            DestroyImmediate(screenMat);
        }
    }
}
