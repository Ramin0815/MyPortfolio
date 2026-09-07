Shader "Custom/TestShader"
{
    Properties
    {
    	_BaseColor("Base Color", Color) = (1,1,1,1)
        [Gamma] _Metallic( "Metallic" , Range( 0.0 , 1.0 )) = 0.5 
        _Smoothness( " Smoothness" , Range( 0.0 , 1.0 )) = 0.5 
        _LayerCount("Layer Count", float) = 22.0
        _MaxDepth("Max Depth", float) = 1.0
        _MaskThreshold("Mask Threshold", float) = 0.5
        _NoiseScale("Noise Scale", float) = 1.0

        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [NoiseTexture] _NoiseMap("Noise Map", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "Render Type" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
        }

        LOD 100
        Zwrite ON
        Cull Back

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma prefer_hlslcc gles 
            #pragma exclude_renderers d3d11_9x 
            #pragma target 2.0

            // 머티리얼 키워드 
            #pragma shader_feature _NORMALMAP 
            #pragma shader_feature _ALPHATEST_ON 
            #pragma shader_feature _ALPHAPREMULTIPLY_ON 
            #pragma shader_feature _EMISSION 
            #pragma shader_feature _METAL _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 
            #pragma shader_feature _OCCLUSIONMAP

            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF 
            #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF 
            #pragma shader_feature _SPECULAR_SETUP 
            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            // URP 키워드 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE 
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS 
            #pragma multi_comp 
            #pragma multi_compile _ _SHADOWS_SOFT 
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            // Unity 키워드 
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED 
            #pragma multi_compile _ LIGHTMAP_ON 
            #pragma multi_compile_fog


            #pragma multi_compile_fog 
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //#include "UnityLightingCommon.cginc"

            //기본 데이터
            struct Attributes
            {
                float4 positionOS   : POSITION;
                half3 normal        : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv           : TEXCOORD0;
                float2 uv2          : TEXCOORD1;
                float2 lightmapUV   : TEXCOORD2;
                //half3 diff         : COLOR0;
            };

            //지오메트리->픽셀
            struct g2f
            {
                float4 positionCS   : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                half3 normalWS      : TEXCOORD1;
                float2 uv           : TEXCOORD2;
                DECLARE_LIGHTMAP_OR_SH (lightmapUV, vertexSH, 3 );
                float2 uv2          : TEXCOORD4;
                int layer           : TEXCOORD5;
                float4 fogNLight    : TEXCOORD6;
            };

            //버퍼
            //TEXTURE2D(_BaseMap);
            //SAMPLER(sampler_BaseMap);

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);

            CBUFFER_START(CustomFurProps) 
                float _LayerCount; 
                float _MaxDepth;
                float _MaskThreshold; 
                float4 _NoiseMap_ST; 
            CBUFFER_END

            //버텍스
            Attributes vert(Attributes IN)
            {
                return IN;
            }

            //지오메트리
            [maxvertexcount(45)] 
            void geom(triangle Attributes input[3], inout TriangleStream<g2f> OutputStream)
            {
                g2f output;

                float3 posWS[3];
                float4 posCS[3];
                half3 normalWS[3];

                for(int i = 0; i < 3; i++){
                    posWS[i] = TransformObjectToWorld(input[i].positionOS.xyz);
                    posCS[i] = TransformObjectToHClip(input[i].positionOS.xyz);
                    normalWS[i] = TransformObjectToWorldNormal(input[i].normal);

                    output.positionCS = posCS[i];
                    output.positionWS = posWS[i];
                    output.normalWS = normalWS[i]; 
                    output.uv = TRANSFORM_TEX(input[i].uv, _BaseMap);
                    output.uv2 = TRANSFORM_TEX(input[i].uv2, _NoiseMap);
                    output.layer = 0;
                    output.fogNLight = half4(ComputeFogFactor(TransformObjectToHClip(input[i].positionOS.z)),VertexLighting(posWS[i], normalWS[i]));
                    OUTPUT_LIGHTMAP_UV (input[i].lightmapUV, unity_LightmapST, output.lightmapUV);
                    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                    OutputStream.Append(output);
                }

                OutputStream.RestartStrip();

                float layerCount = max(1.0, floor(_LayerCount));

                for (int layer = 0; layer < layerCount; ++layer)
                {
                    // 현재 층의 팽창 깊이 계산
                    float depthFactor = (layer + 1.0f) / layerCount;
                    float currentDepth = _MaxDepth * depthFactor;
                    
                    for (int i = 0; i < 3; i++)
                    {
                        float4 positionOS = input[i].positionOS; // 원본 오브젝트 공간 위치

                        // 노말 벡터 처짐 계산

                        float3 originalNormal = input[i].normal;
                        float3 worldNormal = normalWS[i];
                        float3 processedNormal = worldNormal; // 처짐이 적용될 최종 노말

                        // Y-down 60도 처짐 로직 적용 (월드 공간에서 수행)
                        // Y축이 양수인 면 (지붕 윗면)에만 처짐 적용
                        if (worldNormal.y > 0.0f && worldNormal.y < 0.96f) 
                        {
                            float nx = worldNormal.x;
                            float ny = worldNormal.y;
                            float nz = worldNormal.z;
                            
                            // 회전 축 k의 크기 제곱: k = (n_z, 0, -n_x)
                            float K_sq = nx * nx + nz * nz;
                            
                            if (K_sq > 0.0001f)
                            {
                                float K = sqrt(K_sq);
                                // 60도 회전 상수
                                const float COS_60 = 0.5f;
                                const float SIN_60 = 0.866025f; // sqrt(3) / 2
                                
                                // k x n 계산 
                                // k x n = (n_x n_y, -(n_x^2+n_z^2), n_y n_z)
                                float3 k_cross_n = float3(
                                    nx * ny,
                                    -(nx * nx + nz * nz),
                                    ny * nz
                                );

                                processedNormal = worldNormal * COS_60 + (k_cross_n / K) * SIN_60;
                                processedNormal = normalize(processedNormal);
                            }
                            posCS[i] = TransformWorldToHClip(posWS[i]+processedNormal*currentDepth);
                        }
                        
                        output.positionCS = posCS[i];
                        output.positionWS = posWS[i];
                        output.normalWS = normalWS[i]; 
                        
                        output.uv = TRANSFORM_TEX(input[i].uv, _BaseMap);
                        output.uv2 = TRANSFORM_TEX(input[i].uv2,_NoiseMap);
                        output.layer = layer+1;
                        output.fogNLight = half4(ComputeFogFactor(posCS[i].z),VertexLighting(posWS[i], normalWS[i]));
                        OUTPUT_LIGHTMAP_UV (input[i].lightmapUV, unity_LightmapST, output.lightmapUV);
                        OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                        OutputStream.Append(output);
                    }

                    OutputStream.RestartStrip();
                }
            }

            //픽셀
            half4 frag(g2f IN) : SV_Target
            {
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float4 noise = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, IN.uv2);
                // 앞으로 갈수록 노이즈 텍스처가 어두워지고 가늘어지도록 
                float alpha = noise.r * ( 1.0 - IN.layer);
                if (IN.layer > 0.0 && alpha < _MaskThreshold) discard;

                float occlusion = lerp( 0, 1.0 , IN.layer);

                /*
                float3 color = baseColor*occlusion;
                color = MixFog(color,IN.fogNLight.x);

                return float4(color,alpha) * _BaseColor;
                */

                SurfaceData surfaceData = (SurfaceData) 0 ;
                //InitializeStandardLitSurfaceData(IN.uv.xy, surfaceData);
                surfaceData.albedo =  baseColor;
                surfaceData.occlusion = occlusion;
                surfaceData.metallic = _Metallic; 
                surfaceData.smoothness = _Smoothness;

                InputData inputData = (InputData) 0 ;
                inputData.positionWS = IN.positionWS;
                inputData.normalWS = IN.normalWS;
                inputData.viewDirectionWS = SafeNormalize(GetCameraPositionWS() - inputData.positionWS);
            #if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
                inputData.shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
            #else 
                inputData.shadowCoord = float4( 0 , 0 , 0 , 0 );
            #endif
                inputData.fogCoord = IN.fogNLight.x;
                inputData.vertexLighting = IN.fogNLight.yzw;
                //inputData.vertexLighting = half3(2,1,1);
                inputData.bakedGI = 2;

                float4 color = UniversalFragmentPBR(inputData, surfaceData);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return color*_BaseColor;
            }
            ENDHLSL
        }

        Pass{
            Name "DepthOnly" 
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore 
            #pragma vertex DepthOnlyVertex 
            #pragma fragment DepthOnlyFragment 
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
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
