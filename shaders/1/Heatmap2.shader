Shader "Unlit/Heatmap2"
{
    Properties
    {
        _MainTex ("Base Map (RGB)", 2D) = "white" {}
        _HeatTex("Heatmap Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags {"Queue" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct vertInput
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct vertOutput
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _HeatTex;
            uniform int _Points_Length;
            uniform float3 _Points[20];
            uniform float2 _Properties[20];

            vertOutput vert(vertInput input)
            {
                vertOutput o;
                o.pos = UnityObjectToClipPos(input.pos);
                o.uv = input.uv;
                o.worldPos = mul(unity_ObjectToWorld, input.pos).xyz;
                return o;
            }

            half4 frag(vertOutput output) : COLOR
            {
                half4 baseColor = tex2D(_MainTex, output.uv);
                half h = 0;

                for (int i = 0; i < _Points_Length; i++)
                {
                    half di = distance(output.worldPos, _Points[i].xyz);
                    half ri = _Properties[i].x;
                    half hi = 1 - saturate(di / ri);
                    h += hi * _Properties[i].y;
                }

                h = saturate(h);
                half4 heatColor = tex2D(_HeatTex, fixed2(h, 0.5));

                // 根据距离混合
                half4 finalColor = lerp(baseColor, heatColor, h);
                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}