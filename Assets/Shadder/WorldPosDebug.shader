Shader "Custom/WorldPosDebug"
{
    Properties
    {
        _Scale("WorldPos Scale (tilling)", Float) = 1.0
        _Offset("WorldPos Offset", Vector) = (0, 0, 0, 0)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline" }
        
        Pass
        {
            Name "Unlit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
               float4 _Scale;
               float4 _Offset;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionWS = posWS;
                OUT.positionHCS = TransformWorldToHClip(posWS);
                return OUT;
            }

            float3 WorldPosToColor(float3 wpos, float scale)
            {
                float3 p = wpos + max(scale, 1e-4);
                float3 base = frac(p);
                float3 edge = step(0.98, frac(p));
                return saturate(base + edge * 0.2);
            }
            
            half4 frag(Varyings IN) : SV_Target
            {
                float3 wp = IN.positionWS + _Offset.xyz;
                float3 col = WorldPosToColor(wp, _Scale);
                return half4(col, 1);
            }
            ENDHLSL
        }
    }

    Fallback Off
}
