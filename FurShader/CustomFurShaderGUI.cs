using UnityEditor;
using UnityEngine;

public class CustomFurShaderGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // =================================================================
        // 1. 프로퍼티 찾기 (기존 변수 + 신규 PBR/Detail 변수 모두 포함)
        // =================================================================
        MaterialProperty baseMap = FindProperty("_BaseMap", properties);
        MaterialProperty baseColor = FindProperty("_BaseColor", properties);
        MaterialProperty smoothness = FindProperty("_Smoothness", properties);
        MaterialProperty cutoff = FindProperty("_Cutoff", properties);

        // Rendering Toggles
        MaterialProperty specHighlights = FindProperty("_SpecularHighlights", properties);
        MaterialProperty envReflections = FindProperty("_EnvironmentReflections", properties);

        // Metallic & Specular
        // (만약 셰이더에 _WorkflowMode가 없다면 false 처리되어 에러가 나지 않습니다)
        MaterialProperty workflowMode = FindProperty("_WorkflowMode", properties, false); 
        MaterialProperty metallicMap = FindProperty("_MetallicMap", properties);
        MaterialProperty metallicScale = FindProperty("_MetallicScale", properties);
        MaterialProperty specMap = FindProperty("_SpecularMap", properties);
        MaterialProperty specColor = FindProperty("_SpecColor", properties);

        // Normal, Height, Occlusion
        MaterialProperty bumpMap = FindProperty("_BumpMap", properties);
        MaterialProperty occMap = FindProperty("_OcclusionMap", properties);
        MaterialProperty occStrength = FindProperty("_Occlusion", properties);
        MaterialProperty parallaxMap = FindProperty("_ParallaxMap", properties);

        // Emission
        MaterialProperty emiEnabled = FindProperty("_EmissionEnabled", properties);
        MaterialProperty emiColor = FindProperty("_EmissionColor", properties);
        MaterialProperty emiMap = FindProperty("_EmissionMap", properties);

        // Detail Inputs
        MaterialProperty detailMask = FindProperty("_DetailMask", properties);
        MaterialProperty detailAlbedo = FindProperty("_DetailAlbedoMap", properties);
        MaterialProperty detailNormal = FindProperty("_DetailNormalMap", properties);

        // Fur Data
        MaterialProperty furLen = FindProperty("_FurLength", properties);
        MaterialProperty furCount = FindProperty("_FurCount", properties);
        MaterialProperty maskThresh = FindProperty("_MaskThreshold", properties);
        MaterialProperty grav = FindProperty("_GravityStrength", properties);
        MaterialProperty dirMap = FindProperty("_FurDirectionMap", properties);
        MaterialProperty noiseMap = FindProperty("_NoiseMap", properties);
        MaterialProperty lenMap = FindProperty("_FurLengthMap", properties);
        MaterialProperty curlAmplitude = FindProperty("_CurlAmplitude", properties);
        MaterialProperty curlFrequency = FindProperty("_CurlFrequency", properties);
        MaterialProperty clumpStrength = FindProperty("_ClumpStrength", properties);

        // Interaction
        MaterialProperty lerpData = FindProperty("_LerpData", properties);


        // =================================================================
        // 2. UI 그리기 시작
        // =================================================================

        // [그룹 1: 렌더링 옵션]
        EditorGUILayout.LabelField("Rendering Options", EditorStyles.boldLabel);
        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
        {
            materialEditor.ShaderProperty(specHighlights, "Specular Highlights");
            materialEditor.ShaderProperty(envReflections, "Environment Reflections");
        }
        EditorGUILayout.Space(10);

        // [그룹 2: Surface Input (PBR 코어)]
        EditorGUILayout.LabelField("Surface Input", EditorStyles.boldLabel);
        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
        {
            // 한 줄에 텍스처 슬롯과 컬러 피커를 동시에 배치
            materialEditor.TexturePropertySingleLine(new GUIContent("Albedo"), baseMap, baseColor);

            // 워크플로우(Metallic / Specular) 분기 UI
            if (workflowMode != null)
            {
                EditorGUI.BeginChangeCheck();
                
                // 1. 멋진 드롭다운(Popup) 메뉴를 그립니다.
                string[] options = new string[] { "Specular Workflow", "Metallic Workflow" };
                int currentMode = (int)workflowMode.floatValue;
                currentMode = EditorGUILayout.Popup("Workflow Mode", currentMode, options);

                // 2. 만약 드롭다운 값을 바꿨다면?
                if (EditorGUI.EndChangeCheck())
                {
                    workflowMode.floatValue = currentMode;
                    
                    // 셰이더 내부의 키워드를 확실하게 켜고 꺼줍니다!
                    // mode 1은 Metallic, mode 0은 Specular
                    SetKeyword(materialEditor, "_METALLIC", currentMode == 1);
                    SetKeyword(materialEditor, "_SPECULAR", currentMode == 0); 
                }

                // 3. 선택된 모드에 따라 맵과 슬라이더를 다르게 띄워줍니다.
                EditorGUI.indentLevel++;
                if (currentMode == 1) // Metallic 선택 시
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map"), metallicMap, metallicScale);
                }
                else // Specular 선택 시
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Specular Map"), specMap, specColor);
                }
                EditorGUI.indentLevel--;
            }
            else
            {
                // 변수가 없을 때의 예비 처리
                materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map"), metallicMap, metallicScale);
                materialEditor.TexturePropertySingleLine(new GUIContent("Specular Map"), specMap, specColor);
            }

            materialEditor.ShaderProperty(smoothness, "Smoothness");

            // Normal, Height, Occlusion 배치
            materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map"), bumpMap);
            materialEditor.TexturePropertySingleLine(new GUIContent("Height Map"), parallaxMap);
            // 오클루전은 맵과 강도 조절 슬라이더를 한 줄에!
            materialEditor.TexturePropertySingleLine(new GUIContent("Occlusion Map"), occMap, occStrength);

            materialEditor.ShaderProperty(cutoff, "Alpha Clipping");

            // Emission (기존 코드 버그 수정됨: BeginChangeCheck 필수)
            EditorGUI.BeginChangeCheck(); 
            materialEditor.ShaderProperty(emiEnabled, "Emission");
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword(materialEditor, "_EMISSION_ON", emiEnabled.floatValue == 1.0f);
            }

            if (emiEnabled.floatValue == 1.0f)
            {
                EditorGUI.indentLevel++;
                materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map & Color"), emiMap, emiColor);
                EditorGUI.indentLevel--;
            }
        }
        EditorGUILayout.Space(10);

        // [그룹 3: Detail Inputs]
        EditorGUILayout.LabelField("Detail Inputs", EditorStyles.boldLabel);
        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
        {
            materialEditor.TexturePropertySingleLine(new GUIContent("Detail Mask"), detailMask);
            materialEditor.TexturePropertySingleLine(new GUIContent("Detail Albedo"), detailAlbedo);
            materialEditor.TexturePropertySingleLine(new GUIContent("Detail Normal"), detailNormal);
        }
        EditorGUILayout.Space(10);

        // [그룹 4: Fur Data]
        EditorGUILayout.LabelField("Fur Data", EditorStyles.boldLabel);
        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
        {
            materialEditor.ShaderProperty(furLen, "Fur Length");
            materialEditor.ShaderProperty(furCount, "Layer Count");
            materialEditor.ShaderProperty(maskThresh, "Mask Threshold");
            materialEditor.ShaderProperty(grav, "Gravity Offset");
            
            EditorGUILayout.Space(5);
            materialEditor.TexturePropertySingleLine(new GUIContent("Flow Map"), dirMap);
            materialEditor.TexturePropertySingleLine(new GUIContent("Noise Map"), noiseMap);
            EditorGUI.indentLevel++; // 살짝 들여쓰기해서 종속된 느낌 주기
            materialEditor.TextureScaleOffsetProperty(noiseMap); // 타일링 UI 생성
            EditorGUI.indentLevel--;

            materialEditor.TexturePropertySingleLine(new GUIContent("Length Map"), lenMap);

            EditorGUILayout.Space(5);
            materialEditor.ShaderProperty(curlAmplitude, "Curl Amplitude");
            materialEditor.ShaderProperty(curlFrequency, "Curl Frequency");
            materialEditor.ShaderProperty(clumpStrength, "Clump Strength");
        }
        EditorGUILayout.Space(10);

        // [그룹 5: Interaction]
        EditorGUILayout.LabelField("Interaction", EditorStyles.boldLabel);
        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
        {
            materialEditor.ShaderProperty(lerpData, "Interaction Lerp");
        }
    }

    private void SetKeyword(MaterialEditor editor, string keyword, bool state)
    {
        foreach (Material m in editor.targets)
        {
            if (state) m.EnableKeyword(keyword);
            else m.DisableKeyword(keyword);
        }
    }
}
