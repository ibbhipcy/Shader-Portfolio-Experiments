Shader "Unlit/Mixshader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlendTex ("Blend Texture", 2D) = "white" {}
        _Opacity ("Blend Opacity", Range (0, 1)) = 1 // 控制最终混合的颜色深度
        _DepthPower ("Depth power", Range (0, 0.5)) = 0.2 // 控制混合曲线变化的快慢
        _BlendStart ("Blend Start", Range (0, 1)) = 0.2 // 开始混合的深度

        //BSC
        _Brightness("Brightness", Range(0.0, 2)) = 1.0
        _Saturation("Saturation", Range(0.0, 2)) = 1.0
        _Contrast("Contrast", Range(0.0, 2)) = 1.0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _BlendTex;
            float _Opacity;
            float _DepthPower;
            float _BlendStart;
            sampler2D _CameraDepthTexture;

            //BSC 参数
            fixed _Brightness;
            fixed _Saturation;
            fixed _Contrast;

            //BSC
            float3 ContrastSaturationBrightness(float3 color, float brt, float sat, float con)
            {
                float AvgLumR = 0.5;
                float AvgLumG = 0.5;
                float AvgLumB = 0.5;
                float3 LuminanceCoeff = float3(0.2125, 0.7154, 0.0721);
                
                float3 AvgLumin = float3(AvgLumR, AvgLumG, AvgLumB);
                float3 brtColor = color * brt;
                float intensityf = dot(brtColor, LuminanceCoeff);
                float3 intensity = float3(intensityf, intensityf, intensityf);
                
                float3 satColor = lerp(intensity, brtColor, sat);
                float3 conColor = lerp(AvgLumin, satColor, con);
                return conColor;
            }

            fixed4 frag (v2f_img i) : SV_Target
            {
                // 场景颜色
                fixed4 scene = tex2D (_MainTex, i.uv);

                // 混合贴图颜色
                fixed4 blend = tex2D (_BlendTex, i.uv);

                // 深度计算
                float depth = UNITY_SAMPLE_DEPTH (tex2D (_CameraDepthTexture, i.uv));
                depth = Linear01Depth (depth);
                depth = pow (depth, _DepthPower);

                // 低于 BlendStart 完全不混合
                float blendWeight = saturate ((depth - _BlendStart) / (1 - _BlendStart)); //depth 小于 blend start 或者 blend start 大于 1 的值就会被直接裁掉变成 0 或 1
                // 混合最终颜色深度参数
                blendWeight *= _Opacity;
                // 混合
                fixed4 finalColor = lerp (scene, blend, blendWeight);
                //BSC 应用
                finalColor.rgb = ContrastSaturationBrightness (finalColor.rgb, _Brightness, _Saturation, _Contrast);
                return finalColor;
            }
            ENDCG
        }
    }
    FallBack Off
}
