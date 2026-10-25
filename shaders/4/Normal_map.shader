Shader "Unlit/Normal_map"
{
    Properties //在 Unity Inspector 面板中显示可调节的参数，方便美术调整
    {
        _NormalMap("Normal Map",2D)="normal"{}// 法线贴图纹理属性
        _BaseColor("Color",Color)=(1,1,1,1)// 基础颜色属性
        _SpecPower("Specular Power", Range(1,200)) = 50 // 高光强度/范围
        _SpecIntensity("Specular Intensity", Range(0,1)) = 0.5 // 高光亮度
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            // compile shader into multiple variants, with and without shadows
            // (we don't care about any lightmaps yet, so skip these variants)
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            // shadow helper functions and macros
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata_my
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;     // 必须加，否则取不到法线
                float4 tangent : TANGENT;   // 必须加，否则取不到切线
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0; // 世界空间顶点位置（备用）

                float3 tspace0 : TEXCOORD1;// 切线空间→世界空间转换矩阵的第1行
                float3 tspace1 : TEXCOORD2;// 转换矩阵的第2行
                float3 tspace2 : TEXCOORD3;// 转换矩阵的第3行

                float2 uv : TEXCOORD4;// 最终的UV坐标（带缩放/偏移）
                float4 pos : SV_POSITION;// 裁剪空间位置（用于渲染）

                float3 halfDir : TEXCOORD5;

                SHADOW_COORDS(6)
            };

            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float4 _BaseColor;
            float _SpecPower;
            float _SpecIntensity;

            //顶点着色器（vert）：把模型空间的切线 / 法线 / 副切线转换到世界空间
            v2f vert (appdata_my v) //appdata_tan是 Unity 内置结构体（替代了自定义的 appdata）
            //除了position和texcoord0之外tan还包括了normal和tangent
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);// 裁剪空间位置（用于渲染）
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//物体坐标系转换到世界坐标系

                float3 wNormal = UnityObjectToWorldNormal(v.normal);// 世界空间法线
                float3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);// 世界空间切线
                float3 wBitangent = cross(wNormal,wTangent)*v.tangent.w; // 世界空间副切线（叉乘得到）

                //构建转换矩阵（每行对应一个轴）
                o.tspace0 = float3(wTangent.x,wBitangent.x,wNormal.x);// 切线轴的XYZ分量
                o.tspace1 = float3(wTangent.y,wBitangent.y,wNormal.y);// 副切线轴的XYZ分量
                o.tspace2 = float3(wTangent.z,wBitangent.z,wNormal.z);// 法线轴的XYZ分量
                o.uv = TRANSFORM_TEX(v.texcoord, _NormalMap);//UV坐标处理（缩放/偏移

                //half向量计算移动到这里
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
                o.halfDir = normalize(lightDir + viewDir);

                TRANSFER_SHADOW(o)//接受阴影
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed3 tnormal = UnpackNormal(tex2D(_NormalMap, i.uv));//采样法线贴图并解包
                float3 worldNormal;

                //点乘（dot）
                //normalize → 确保向量长度为 1（单位向量）
                worldNormal.x = dot(normalize(i.tspace0),tnormal);
                worldNormal.y = dot(normalize(i.tspace1),tnormal);
                worldNormal.z = dot(normalize(i.tspace2),tnormal);
                //漫反射光照计算
                float4 c = _BaseColor;//底色

                // float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                // float3 halfDir = normalize(lightDir + viewDir);

                float NdotL = saturate(dot(worldNormal, normalize(_WorldSpaceLightPos0.xyz)));
                float3 diffuse = _BaseColor.rgb * _LightColor0.rgb * NdotL;

                float NdotH = saturate(dot(worldNormal, i.halfDir));
                float3 specular = _LightColor0.rgb * pow( (float)NdotH, (float)(200-_SpecPower) ) * _SpecIntensity;

                c.rgb = diffuse + specular;

                c.rgb *= SHADOW_ATTENUATION(i);
                return c;
            }
            ENDCG
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert (appdata v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
