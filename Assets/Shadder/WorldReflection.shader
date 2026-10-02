Shader "Custom/WorldReflection"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "White" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        
        _EnvCube ("Reflection Cubemap", Cube) = ""{}
        _EnvIntensity ("Reflection Intensity", Range(0, 2)) = 1.0
        _EnvBlend ("Reflection Blend (0=Base,1=Env)", Range(0, 1)) = 1.0
        _FresnelPow ("Fresnel Power", Range(0.1, 8)) = 5.0
        _FresnelBoost ("Fresnel Boost", Range(0, 2)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline" }
        
        Pass
        {
            Name "Unlit"
            Tags {"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv0: TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURECUBE(_EnvCube);
            SAMPLER(sampler_EnvCube);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseMap_ST;
                float _EnvIntensity;
                float _EnvBlend;
                float _FresnelPow;
                float _FresnelBoost;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 nrmWS = TransformObjectToWorld(IN.normalOS);
                
                OUT.positionWS = posWS;
                OUT.normalWS = nrmWS;
                OUT.positionHCS = TransformWorldToHClip(posWS);
                OUT.uv = TRANSFORM_TEX(IN.uv0, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).rgb * _BaseColor.rgb;
                
                float3 V = SafeNormalize(GetWorldSpaceViewDir(IN.positionWS));
                
                float3 N = SafeNormalize(IN.normalWS);
                
                float3 R = reflect(-V, N);
                
                half3 envCol = SAMPLE_TEXTURECUBE(_EnvCube, sampler_EnvCube, R).rgb * _EnvIntensity;
                
                float ndtov = saturate(dot(N, V));
                
                float fresnel = pow(1.0 - ndtov, _FresnelPow) * _FresnelBoost;
                
                envCol += (1.0 + fresnel);
                
                half3 finalCol = lerp(baseCol, envCol, _EnvBlend);
                return half4(finalCol, 1.0);
            }
            ENDHLSL
        }
    }
}
