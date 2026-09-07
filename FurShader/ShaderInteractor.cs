using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;

public class ShaderInteractor : MonoBehaviour
{
    [Header("Settings")]
    public Transform interactorObject; // 상호작용할 물체 (예: 플레이어, 손)
    public float radius = 0.1f;        // 셰이더에 전달할 반경
    public bool isLeft = false;

    private int posID;
    private int radiusID;
    private int vecID;
    private Vector3 beforePos;

    private Vector3 smoothedPos;
    private Vector3 smoothedVector;

    void Start()
    {
        beforePos = transform.position;
        // 셰이더 프로퍼티 이름 문자열을 ID로 변환 (Update에서 문자열 쓰면 느림)
        if(isLeft){
            posID = Shader.PropertyToID("_LeftInteractionPos");
            vecID = Shader.PropertyToID("_LeftHandVector");
        }
        else  {
            posID = Shader.PropertyToID("_RightInteractionPos");
            vecID = Shader.PropertyToID("_RightHandVector");
        }
        radiusID = Shader.PropertyToID("_InteractionRadius");
    }

    void Update()
    {
            Vector3 targetPos = interactorObject.position;
            Vector3 deltaMove = targetPos - beforePos;
            
            Shader.SetGlobalVector(posID, targetPos);
            Shader.SetGlobalFloat(radiusID, radius);

            if (deltaMove.magnitude > 0)
            {
                Vector3 rawMoveVector = deltaMove.normalized;
                
                // 방향 전환의 부드러움(관성)을 결정하는 가중치입니다. (0 ~ 1)
                // 값이 높을수록 기존 털의 결을 고집스럽게 유지하려 합니다.
                float inertiaWeight = 0.85f; 
                
                // 기존 방향(smoothedVector)에 새 방향(rawMoveVector)을 비례해서 더합니다.
                Vector3 blendedVector = (smoothedVector * inertiaWeight) + (rawMoveVector * (1.0f - inertiaWeight));

                 smoothedVector = Vector3.Slerp(smoothedVector, rawMoveVector, Time.deltaTime * 10);
                
                Shader.SetGlobalVector(vecID, smoothedVector);
            }

            beforePos = targetPos;
    }
}
