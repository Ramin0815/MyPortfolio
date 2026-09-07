Shader "Custom/JagaeShader"
{
Properties
    {
        [Header(Base Properties)]
        _BaseColor("Base Color", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.9 // 높은 광택 유지
        _Specular("Specular", Color) = (1,1,1,1)

        [NoiseTexture] _NoiseMap("Noise Map", 2D) = "white" {}
        
        [Header(Iridescence)]
        _IridescenceThickness("Thickness (nm)", Range(0.0, 1000.0)) = 500.0 // 나노미터 두께 시뮬레이션
        _IridescenceIOR("IOR (n)", Range(1.0, 3.0)) = 1.6 // 굴절률 (Refractive Index)
        _IridescenceStrength("Iridescence Strength", Range(0.0, 1.0)) = 0.8
    }
    SubShader
    {
        Tags { "LightMode" = "UniversalForward" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        ZWrite On
        Cull Back

        Pass
        {
            HLSLPROGRAM
            #define _SPECULAR_COLOR_SPECULAR_COLOR
            #define _CLEARCOAT _CLEARCOATMAP

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalLS   : NORMAL;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS    : TEXCOORD0;
                float3 positionWS  : TEXCOORD1;
                float2 uv          : TEXCOORD2;
                float2 uv2         : TEXCOORD3;
                float3 viewDirWS   : TEXCOORD4;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _NoiseMap_ST;
                float _Smoothness;
                half4 _Specular;
                half _IridescenceThickness; // half로 최적화
                half _IridescenceIOR;
                half _IridescenceStrength;
            CBUFFER_END

            float3 Iridescence(float NdotV, float thickness, float IOR)
            {
                // 박막 간섭을 시뮬레이션하기 위한 광 경로차 기반 모델
                // NdotV가 1에 가까울수록 OPD가 작아짐
                float OPD = thickness * IOR * (1.0 - NdotV); 
                
                // 파장에 따른 색상 변화를 위한 3개의 위상차를 설정
                // 이 값들은 RGB 파장에 맞게 조절된 임의의 주파수
                const float3 Wavelengths = float3(680.0, 550.0, 470.0); // R, G, B 파장 근사치 (nm)
                const float PI2 = 6.283185; 
                
                // 파장에 따른 위상차 계산: 2 * PI * (OPD / lambda)
                float3 phase = OPD / Wavelengths; 
                
                // 코사인 함수를 이용해 간섭 파형을 시뮬레이션
                float3 interference =  0.5 + 0.5 * cos(phase * PI2);
                
                // 색상 왜곡 방지
                return saturate(interference);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalLS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.uv2 = TRANSFORM_TEX(IN.uv2, _NoiseMap);
                OUT.viewDirWS = GetWorldSpaceViewDir(OUT.positionWS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                InputData lighting = (InputData) 0;
                lighting.positionWS = IN.positionWS;
                lighting.normalWS = normalize(IN.normalWS);
                lighting.viewDirectionWS = normalize(IN.viewDirWS);

                SurfaceData surfaceData = (SurfaceData) 0;
                float4 baseColorAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                surfaceData.albedo = baseColorAlpha.rgb * _BaseColor;
                surfaceData.alpha = 1;
                surfaceData.smoothness = _Smoothness;
                surfaceData.metallic = 0.0;
                surfaceData.clearCoatMask = 1;
                surfaceData.clearCoatSmoothness = 0.8;

                float patternData = Luminance(baseColorAlpha.rgb);
                

                float NdotV = saturate(dot(lighting.normalWS, lighting.viewDirectionWS));
                float thicknessNoise = (patternData -0.5)*500;
                float thickness = max(0,thicknessNoise + _IridescenceThickness);

                float normalNoise = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,IN.uv2).r;
                float NdotV2 = saturate(NdotV + (normalNoise-128)/512);
    
                // 박막 간섭 색상 계산
                float3 iridescenceColor = Iridescence(NdotV2, thickness, _IridescenceIOR);

                surfaceData.specular = lerp(float3(1, 1, 1), half3(iridescenceColor), _IridescenceStrength);
                //surfaceData.specular = _Specular.xyz;

                //return half4(iridescenceColor,1);
                return (0.7 * UniversalFragmentPBR(lighting,surfaceData) * half4(iridescenceColor,1) + 0.5*UniversalFragmentPBR(lighting,surfaceData) + 0.05 * (baseColorAlpha * _BaseColor));
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        
    }
}
