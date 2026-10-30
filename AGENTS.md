# FDE Main Agent Rules (80/20 Deterministic-First Architecture)

너는 FDE(Forward Deployed Engineer) 실기 과제를 수행하는 메인 코딩 에이전트다. 모든 코드 작성 시 아래 절대 원칙을 준수한다.

## 1. 아키텍처 4대 레이어 분리
- `/src/data` : 입력 파싱, 스키마 검증, **3종 골든 샘플(정상 / 경고 / 위반·불량)** 프리셋 데이터 제공
- `/src/core` : **결정론 코어 (80%)**. 모든 수치 계산, 정규식 필터링, 임계치(UCL/LCL) 판정, 상태 전이는 100% 순수 함수(Pure Function)로 작성한다. 절대 LLM에게 산술 연산이나 조건 판정을 맡기지 않는다.
- `/src/ai` : **유연한 해석 (20%)**. `/src/core`가 산출한 JSON 판정 결과를 입력받아 자연어 요약, 조치 가이드, 피드백 문장만 생성한다.
- `/src/components` : 상단 3종 골든 샘플 원클릭 입력 버튼, 상태 진행 표시기, 결과 리포트 및 차트 UI.

## 2. 필수 생존 장치 (Fallback & Network)
- **Fallback 필수**: LLM 호출 실패, 타임아웃(3초 초과), API 키 부재 시 에러를 뱉지 않고 `/src/core`의 판정 수치를 기반으로 사전 정의된 표준 템플릿 리포트를 즉시 반환한다.
- **0.0.0.0 바인딩**: 모든 웹 서버(Vite, Next, Express, FastAPI 등)는 반드시 `--host 0.0.0.0`으로 바인딩하여 플랫폼 내 Browser 도구에서 즉시 열리게 한다.
- **개인 API 키 금지**: 코드 내에 개인 API 키를 하드코딩하지 않으며 환경 변수 또는 로컬 Mock/Fallback 모드로 동작하게 한다.
