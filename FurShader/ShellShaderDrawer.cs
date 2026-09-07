using UnityEngine;

public class ShellShaderDrawer : MonoBehaviour
{
    public SkinnedMeshRenderer skinRenderer; // 강아지의 SkinnedMeshRenderer 연결
    public Material furMaterial; // 방금 만든 털 셰이더 머테리얼 연결
    [Range(1, 50)] public int layerCount = 40;

    void Start()
    {
        // 1. 강아지의 피부에 머테리얼을 layerCount(15개)만큼 겹겹이 입혀줍니다.
        Material[] mats = new Material[layerCount];
        for (int i = 0; i < layerCount; i++)
        {
            mats[i] = furMaterial; // 똑같은 털 머테리얼을 15번 쑤셔 넣음
        }
        skinRenderer.materials = mats;

        // 2. 머테리얼은 똑같지만, 층(Index)마다 _LayerRatio 변수만 다르게 주입합니다!
        MaterialPropertyBlock block = new MaterialPropertyBlock();
        for (int i = 0; i < layerCount; i++)
        {
            float ratio = (float)i / (layerCount - 1);
            
            // 현재 층의 비율을 블록에 기록 (0.0 ~ 1.0)
            block.SetFloat("_LayerRatio", ratio);
            
            // 🌟 핵심: SkinnedMeshRenderer의 i번째 층에만 이 비율을 몰래 전달합니다.
            skinRenderer.SetPropertyBlock(block, i);
        }
    }
}
