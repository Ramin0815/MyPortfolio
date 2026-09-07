# Code Portfolio

게임 클라이언트 프로그래머 지원을 위해 제가 직접 작성한 주요 코드를 모아 정리한 Repository입니다.

Unity/C# 기반 Game Programming부터 HLSL Shader, OpenGL/GLSL, C++/OpenCV까지  
프로젝트와 수업에서 직접 구현한 코드 중 대표적인 내용을 선별했습니다.

> 이 Repository는 각 프로젝트의 전체 Source Code를 보관하기 위한 저장소가 아니라,  
> **제가 직접 구현하거나 주요하게 수정한 코드를 확인할 수 있도록 정리한 Portfolio용 Repository**입니다.
>
> Team Project의 경우 제가 담당한 코드만 선별하였으며,  
> 수업에서 제공된 Framework를 활용한 경우 해당 내용을 별도로 명시했습니다.
>
> 공개에 문제가 없는 코드만 포함하고 있습니다.

---

## Repository Structure

| Folder | Language / Environment | Description |
| --- | --- | --- |
| [`FurShader`](./FurShader) | Unity URP / HLSL / C# | Shell 기반 Fur Shader와 Artist용 Custom Shader GUI |
| [`IKENIE`](./IKENIE) | Unity HDRP / C# | 3D 암살 게임에서 담당한 UI, Data 및 Gameplay 관련 코드 |
| [`Korea_Traditional_Material_Shader`](./Korea_Traditional_Material_Shader) | Unity URP / HLSL | 한국 전통 소재를 표현하기 위해 제작한 Rendering Shader |
| [`OpenGL_CV`](./OpenGL_CV) | C++ / OpenGL / GLSL / OpenCV | Graphics Programming 및 Image Processing / Computer Vision 구현 |

---

# 01. FurShader

### Unity URP / HLSL / C#

Mobile VR 환경에서 털을 표현하기 위해 제작한 **Shell-based Fur Shader**와  
Shader Parameter를 쉽게 조절할 수 있도록 제작한 **Custom Shader GUI** 코드입니다.

기존 Card 방식 Fur의 Rendering Cost를 줄이기 위해 Shell Rendering 방식을 구현했으며,  
Physics Simulation이나 개별 Fur Collider를 사용하지 않고  
Hand Position과 Movement Direction을 이용해 털이 손의 움직임에 반응하도록 구현했습니다.

## Main Implementation

- Shell Layer 기반 Fur Rendering
- Vertex Extrusion을 이용한 Fur Volume 표현
- Hand Position과 Vertex Distance를 이용한 Interaction Weight 계산
- Hand Movement Direction에 따른 Fur Direction 변화
- Physics Simulation 없이 구현한 Visual Fur Interaction
- Unity URP Lit 구조 분석 및 Lighting 기능 결합
- Emission, Height 등 추가 Material 기능 적용
- C# 기반 Custom Shader GUI 구현

## Fur Interaction

털 각각에 Physics Object를 생성하는 대신,  
Shader에서 Hand와 Vertex 사이의 거리와 움직임 방향을 이용해 Vertex 위치를 변화시켰습니다.

이를 통해 VR 환경에서 비교적 적은 연산으로  
손으로 털을 쓸어내리는 것과 유사한 Visual Interaction을 구현했습니다.

## Shader GUI

Shader 기능이 증가하면서 Material Property의 수가 많아졌기 때문에  
Artist가 필요한 기능을 쉽게 찾고 조절할 수 있도록 C# 기반 Custom Shader GUI를 구성했습니다.

단순히 Shader 기능을 추가하는 것뿐 아니라,  
**실제로 다른 작업자가 사용할 때의 Workflow까지 고려하는 경험**을 할 수 있었습니다.

---

# 02. IKENIE

### Unity HDRP / C#

Team Project로 제작한 3D 암살 게임에서  
제가 직접 구현한 주요 C# 코드를 선별한 폴더입니다.

전체 프로젝트 코드가 아니라  
**UI Architecture, Game Data 관리, Gameplay System 및 Integration과 관련하여 제가 담당한 코드**를 중심으로 정리했습니다.

## My Contribution

- Main UI 관리 구조 설계 및 구현
- Abstract Class 기반 UI 공통 동작 정의
- `UIType`과 `Dictionary`를 이용한 UI 관리
- ScriptableObject 기반 Item Data 관리
- Cutscene 및 Gameplay 관련 기능 구현
- Gameplay / Animation / UI System 연결
- 팀원이 구현한 Logic을 기존 Game Flow에 통합

## UI Architecture

Main UI를 중앙에서 관리할 수 있도록  
각 UI Panel이 공통 Abstract Class를 상속하도록 구성했습니다.

`UIManager`는 각 Concrete UI의 구현을 직접 처리하지 않고  
`UIType`을 통해 필요한 UI를 검색한 뒤 공통 `Show / Hide` 동작을 호출합니다.

이를 통해 Inventory, Map 등 서로 다른 Main UI를  
동일한 방식으로 제어할 수 있도록 구성했습니다.

Main UI처럼 상호 배타적으로 표시되는 화면과  
HUD처럼 독립적으로 표시되어야 하는 UI는 역할에 따라 별도로 관리했습니다.

## Data Management

Item과 같이 여러 System에서 반복적으로 사용하는 Data는  
`ScriptableObject`를 활용해 Game Logic과 분리했습니다.

이를 통해 특정 Scene이나 Component에 Data가 직접 종속되는 것을 줄이고,  
여러 System에서 동일한 Item Data를 활용할 수 있도록 구성했습니다.

## Integration

Team Project에서는 개별 기능 구현뿐 아니라  
다른 팀원이 작성한 Logic을 분석하고 Gameplay, Animation, UI와 연결하는 작업도 담당했습니다.

특히 Enemy Tracking 및 Death Logic 자체는 다른 팀원이 구현했으며,  
저는 해당 Logic을 전체 Gameplay Flow와 연결하고 실제 게임에서 정상적으로 동작하도록 통합했습니다.

> 이 폴더에는 가능한 한 제가 직접 작성하거나 담당한 코드만 선별하여 포함했습니다.

---

# 03. Korea Traditional Material Shader

### Unity URP / HLSL

한국 전통 소재의 시각적 특징을  
Real-time Rendering 환경에서 표현하기 위해 제작한 Shader 코드입니다.

주요 구현 대상은 **Thatched Roof**와 **Najeonchilgi**입니다.

---

## Thatched Roof Shader

적은 Geometry를 이용하면서도 볏짚 지붕의 부피감을 표현하기 위해  
Geometry Shader를 이용한 Layer 생성 방식을 실험했습니다.

## Main Implementation

- Geometry Shader 기반 Layer 생성
- Normal Direction을 이용한 Geometry 확장
- Matrix / Vector 연산을 이용한 방향 변화
- 중력 방향을 고려한 볏짚 형태 변화
- URP Lighting 구조 분석
- `SurfaceData`, `InputData` 및 PBR Lighting 구조 분석

---

## Najeonchilgi Shader

나전칠기의 특징인  
**시점에 따라 변화하는 색상과 옻칠 표면의 광택감**을 Real-time Shader로 표현했습니다.

실제 Thin-film Interference 현상을 그대로 Simulation하기보다는  
Real-time Rendering에서 필요한 시각적 특징을 선별해 근사적으로 구현했습니다.

## Main Implementation

- View Direction에 따른 Color 변화
- Thin-film Interference에서 착안한 Iridescence 표현
- Base Color / Diffuse / Angle-dependent Color 조합
- Unity URP Clear Coat 적용
- 옻칠 표면의 광택 표현

---

# 04. OpenGL_CV

### C++ / OpenGL / GLSL / OpenCV

Graphics Programming과 Image Processing / Computer Vision 수업에서  
직접 작성한 대표 C++ 및 Shader 코드를 정리했습니다.

Rendering Pipeline과 Image Processing Algorithm이  
실제로 코드에서 어떤 Data Flow로 처리되는지를 이해하는 것에 중점을 두었습니다.

---

## OpenGL / GLSL

수업에서 제공된 Header 및 기본 Framework 일부를 활용하고,  
각 과제에서 요구된 Rendering Logic과 GLSL Shader를 직접 구현했습니다.

> OpenGL Project 전체 Framework를 처음부터 구현한 것은 아니며,  
> 교수님이 제공한 기본 환경 위에서 과제별 Rendering Logic과 Shader를 구현했습니다.

### Multi-pass Rendering & Post Processing

Framebuffer Object를 이용해 Scene Rendering 결과를 Texture로 저장하고,  
여러 Rendering Pass를 거쳐 후처리 효과를 적용했습니다.

주요 구현 내용은 다음과 같습니다.

- Framebuffer Object 기반 Off-screen Rendering
- Vertical / Horizontal Gaussian Filtering
- Luminance 기반 Edge Detection
- Tone Quantization
- Bump Mapping
- TBN 기반 Normal 처리
- Multi-pass Rendering

### Geometry Shader

Geometry Shader를 이용하여  
Triangle의 Normal과 View Direction 관계를 기준으로 Silhouette을 탐색하고  
Silhouette 주변에 새로운 Geometry를 생성하는 방식을 구현했습니다.

주요 과정은 다음과 같습니다.

- Triangle별 `N · V` 값 계산
- Sign 변화가 발생하는 Edge 탐색
- Silhouette 위치 Interpolation
- 두 Silhouette Point를 이용한 Quad 생성
- Geometry Shader를 이용한 새로운 Primitive 출력

---

## Image Processing / Computer Vision

OpenCV를 활용해 Image Processing과 Computer Vision의 주요 기법을 학습하고,  
일부 Algorithm은 Pixel 단위 연산부터 직접 구현했습니다.

### Image Processing

Box Filter와 Alpha-trimmed Mean Filter에서는  
Image Pixel을 직접 순회하며 Filtering Logic과 Boundary 처리를 구현했습니다.

Skeletonization과 Pyramid 관련 과제에서도  
OpenCV Primitive를 활용하면서 반복 처리 과정과 Data Flow를 직접 구성했습니다.

### Computer Vision

Image에서 Feature를 추출한 뒤  
Matching 결과를 이용해 두 Image 사이의 Geometric Relationship을 계산하는 과정을 학습했습니다.

SIFT, Hough Transform, RANSAC 등의 Algorithm 자체는  
OpenCV에서 제공하는 구현을 활용했습니다.

---

# What This Repository Shows

이 Repository는 하나의 특정 기술보다  
게임 클라이언트 개발 과정에서 경험한 여러 Programming Layer를 보여주기 위해 구성했습니다.

```text
Gameplay Programming
        ↓
Unity Architecture / Data Management
        ↓
Real-time Shader Programming
        ↓
Graphics Pipeline
        ↓
Image Processing / Computer Vision
```

Unity Project에서는 System 간 관계와 Data 관리 구조를 고민했고,  
Shader Programming에서는 Rendering 과정과 Vector / Matrix 연산을 다뤘습니다.

OpenGL에서는 Rendering Pipeline을 보다 Low-level에서 구현했으며,  
OpenCV에서는 Image를 Data로 바라보고 여러 처리 단계를 Pipeline으로 구성하는 경험을 했습니다.

이러한 경험을 통해 기능을 단순히 구현하는 것뿐 아니라  
**현재 다루는 Data가 어디에서 생성되고, 어떤 과정을 거쳐 최종 결과로 이어지는지 파악하며 코드를 작성하는 습관**을 익혔습니다.

---

# Portfolio

각 프로젝트의 전체 결과물, Gameplay 영상, Architecture Diagram,  
구현 과정과 문제 해결 내용은 별도의 Notion Portfolio에 정리되어 있습니다.

- **Notion Portfolio:** [Portfolio Link]