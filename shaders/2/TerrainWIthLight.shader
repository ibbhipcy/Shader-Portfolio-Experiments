Shader "Unlit/TerrainWithLight"
{
    Properties
    {
        _MainTint ("Diffuse Tint", Color) = (1,1,1,1) //整体颜色

        // 只保留 2 张贴图
        _LowTex("Low Texture", 2D) = "white"{}        // 低处纹理
        _HighTex("High Texture", 2D) = "white"{}      // 高处纹理

        // 高度混合参数
        _HeightScale("Height Scale", Range(0, 1)) = 2 //高度起始
        _HeightOffset("Height Offset", Range(0,10)) = 0 //渐变高度范围

        // 半径范围染色（从第一个Shader合并进来）
        _Center("Center",Vector) = (200,0,200,0)
        _MaxDist("Max Distance", Float) = 5
        _TintColor("Tint Color", Color) = (1,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma target 3.0

            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata_my
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;     // 必须加，否则取不到法线
                float4 tangent : TANGENT;   // 必须加，否则取不到切线
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                UNITY_FOG_COORDS(1)
                
                // 2 个 UV
                float2 uv_LowTex : TEXCOORD2;
                float2 uv_HighTex : TEXCOORD3;

                //优化：通过世界高度来融合
                float3 worldPos : TEXCOORD7; 

                float3 worldNormal : TEXCOORD8;

                SHADOW_COORDS(9)
            };

            // 声明 2 张贴图
            sampler2D _LowTex;
            sampler2D _HighTex;
            float4 _MainTint;

            // 高度混合参数
            float _HeightScale;
            float _HeightOffset;

            // 纹理平铺参数
            float4 _LowTex_ST;
            float4 _HighTex_ST;

            // 半径范围染色参数
            float3 _Center;
            float _MaxDist;
            fixed4 _TintColor;
            
            v2f vert (appdata_my v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 简化：只传递 2 个 UV
                o.uv_LowTex = TRANSFORM_TEX(v.uv, _LowTex); //TRANSFORM_TEX => v.uv * _LowTex_ST.xy + _LowTex_ST.zw
                o.uv_HighTex = TRANSFORM_TEX(v.uv, _HighTex); //让uv能够平移缩放

                //计算世界坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // 世界法线
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                TRANSFER_SHADOW(o)//接受阴影

                UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 获取高度(归一化的)
                //float height = saturate((i.worldPos.y + _HeightOffset) * _HeightScale);
                
                // 采样 2 张贴图
                float4 lowTex  = tex2D(_LowTex, i.uv_LowTex);   // 低处
                float4 highTex = tex2D(_HighTex, i.uv_HighTex); // 高处
                
                float blendFactor = smoothstep(_HeightScale, _HeightScale + _HeightOffset, i.worldPos.y);
                float4 final = lerp(lowTex, highTex, blendFactor);

                // 整体颜色叠加
                final *= _MainTint;
                
                final = saturate(final); //归一化颜色值

                float d = distance(_Center, i.worldPos);
                float strength = 1 - saturate(d / _MaxDist);
                final.rgb = lerp(final.rgb, _TintColor.rgb, strength);

                // 光照
                float3 worldNormal = normalize(i.worldNormal);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                // 漫反射
                float NdotL = saturate(dot(worldNormal, lightDir));
                float3 diffuse = NdotL * 0.6 + 0.1; // 环境光+漫反射，不覆盖颜色

                //加上漫反射
                final.rgb *= diffuse * _LightColor0.rgb;

                // 加上阴影
                final.rgb *= SHADOW_ATTENUATION(i);

                final = saturate(final);

                UNITY_APPLY_FOG(i.fogCoord, final);
                return final;
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
    FallBack "Unlit/Texture"
}