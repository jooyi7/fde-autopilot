# 🚀 FDE-Autopilot 실전 사용자 가이드 (Step-by-Step)

이 가이드는 `fde-autopilot` 키트를 처음 접하는 분들도 처음부터 끝까지 막힘없이 프로젝트를 분석, 설계, 개발, 검증 및 최종 제출할 수 있도록 돕는 **통합 실행 매뉴얼**입니다. 

작업 중 터미널 명령어가 헷갈릴 때는 언제든 **`PLAYBOOK_CLI.md`** 파일을 열어 복사해서 사용할 수 있는 명령어 모음집(Cheat Sheet)으로 활용하세요.

---

## 📂 전체 파일 구성 한눈에 보기 (24개 파일)

작업을 시작하기 전, 어떤 파일들이 준비되어 있는지 가볍게 확인하세요.

* **루트 폴더 (`/`)**: 초기 원클릭 실행 스크립트(`bootstrap.sh`), 환경 설정 파일(`config.toml`), 전체 가이드 및 규칙 문서(`README.md`, `USER_GUIDE.md`, `PLAYBOOK_CLI.md`, `AGENTS.md`, `AUDITOR_GUIDE.md`)
* **`engine/` 폴더**: 폴더 및 데이터 자동 분석(`workspace_inspector.py`, `workspace_profiler.py`), 앱 뼈대 자동 생성(`scaffold_app.sh`), 핵심 로직 테스트(`verify_core.mjs`, `deterministic_harness.mjs`), 품질 및 최종 검수 도구(`auditor_worker.sh`, `release_gate.py`, `final_gatekeeper.sh`, `final_gatekeeper.py`)
* **`prompt_bank/` 폴더**: 요구사항 질문지(`stakeholder_inquiry.md`), 문제 유형 판별법(`typing_guide.md`), 도메인 배경지식(`domain_dm_playbook.md`), 단계별 AI 코딩 프롬프트(`step_by_step_prompts.md`)
* **`blueprints/` 폴더**: 4가지 대표적인 프로젝트 유형별(Type A~D) 상세 아키텍처 및 UI 설계도
* **`docs_kit/` 폴더**: 기획서(`SPEC_TEMPLATE.md`), 기술 의사결정 기록(`ARCHITECTURE_DECISIONS.md`), 방어 논리 가이드(`defense_logic_guide.md`), 최종 인계서(`HANDOFF_TEMPLATE.md`)

---

## 🏁 Step 1. 작업 환경 준비 및 데이터 자동 분석 (초기 15분)

가장 먼저 내 작업 폴더에 어떤 파일과 데이터가 들어있는지 스크립트를 통해 자동으로 파악합니다. 일일이 데이터 파일을 열어보며 시간을 낭비하지 마세요.

### 1. 기본 안내서 확인 (`README.md`, `USER_GUIDE.md`)
* 프로젝트를 시작하기 전 두 파일을 가볍게 읽어 전체 흐름을 파악합니다.

### 2. 원클릭 초기 진단 실행 (`bootstrap.sh`)
* 터미널을 열고 아래 명령어를 입력합니다. (만약 작업할 데이터 폴더가 다른 곳에 있다면 뒤에 경로를 적어줍니다.)
  ```bash
  bash bootstrap.sh --workspace .
  ```
* **이 명령어가 하는 일**: 내부적으로 아래 두 개의 파이썬 분석 스크립트를 자동으로 실행하여 `.autopilot/` 폴더 안에 분석 결과 보고서를 만들어 줍니다.
  * **`engine/workspace_inspector.py`**: 현재 폴더 안의 파일 목록, 문서, 데이터 파일(CSV, JSON, SQLite 등)의 위치와 용량을 스캔하여 `.autopilot/workspace_scan.md` 파일로 정리합니다.
  * **`engine/workspace_profiler.py`**: 발견된 데이터 파일의 컬럼명, 결측치(비어있는 값), 샘플 데이터, 그리고 문서에 적힌 핵심 키워드를 추출하여 `.autopilot/workspace_profile.md` 파일로 요약해 줍니다.

### 3. 분석 보고서 확인하기
* 방금 자동으로 생성된 **`.autopilot/workspace_profile.md`** 파일을 열어봅니다.
* 제공된 데이터에 어떤 항목들이 있는지, 문서에서 요구하는 핵심 단어가 무엇인지 1분 만에 파악할 수 있습니다.

---

## 🎯 Step 2. 프로젝트 유형(Type A~D) 결정 및 기획 확정

데이터와 요구사항을 확인했다면, 우리가 만들 프로그램이 어떤 유형인지 정하고 설계도를 선택합니다.

### 1. 도메인 지식 및 용어 파악 (`prompt_bank/domain_dm_playbook.md`)
* 만약 요구사항 문서에 낯선 현업 용어(예: 공정, 수율, 센서, 알람, 승인 워크플로우 등)가 있다면 이 파일을 열어보세요.
* 현업 담당자들이 무엇을 중요하게 생각하는지, 화면에 어떤 지표를 띄워야 좋아하는지 핵심 배경지식이 정리되어 있습니다.

### 2. 프로젝트 유형 판별하기 (`prompt_bank/typing_guide.md`)
* `typing_guide.md` 파일을 열고 오늘 해결해야 할 과제가 **Type A, B, C, D 중 어디에 속하는지** 결정합니다. (하나의 주 유형을 고르고, 필요하면 보조 유형을 하나 더 고를 수 있습니다.)

### 3. 맞춤형 설계도(Blueprint) 확인 (`blueprints/` 폴더 내 파일 택 1)
방금 결정한 유형에 맞는 설계도 파일을 열어 화면 구성과 필수 기능을 확인합니다.
* **Type A (`blueprints/type_a_dashboard_fdc_wafer_yield.md`)**: **이상 탐지 및 모니터링 대시보드**. 센서 데이터나 지표를 차트로 보여주고, 불량/위험 신호를 색상과 표로 필터링해 주는 화면을 만들 때 사용합니다.
* **Type B (`blueprints/type_b_validator_diff_interview_alarm.md`)**: **데이터 검증 및 비교(Diff) 도구**. 입력된 설정값이나 파일이 규칙에 맞는지 검사하고, 이전 버전과 무엇이 달라졌는지 비교해 오류 알람을 띄우는 도구를 만들 때 사용합니다.
* **Type C (`blueprints/type_c_policy_rag_citation_search.md`)**: **문서 검색 및 출처(Citation) 기반 질의응답**. 매뉴얼이나 규정 문서를 검색하고, 답변을 보여줄 때 반드시 원본 문서의 어느 부분(근거 문장)을 참고했는지 함께 보여줘야 할 때 사용합니다.
* **Type D (`blueprints/type_d_state_machine_pm_backoffice.md`)**: **상태 관리 및 승인 백오피스**. 작업 요청 → 검토 → 승인/반려처럼 단계별로 상태(State)가 바뀌고, 권한에 따라 버튼이 활성화되거나 처리 이력(Audit Log)을 남겨야 할 때 사용합니다.

### 4. 애매한 요구사항 질문하기 (`prompt_bank/stakeholder_inquiry.md`)
* 담당자나 평가자에게 질문할 기회가 있다면 이 파일을 엽니다.
* *"데이터에 빈 값이 있으면 어떻게 처리할까요?"*, *"가장 우선순위가 높은 사용자 1명은 누구인가요?"* 등 여기에 적힌 질문 템플릿을 그대로 활용해 날카롭게 질문하고 답변을 메모해 둡니다. (`docs_kit/stakeholder_inquiry.md` 파일과 동일한 내용입니다.)

### 5. 환경 설정 및 1페이지 기획서 작성 (`config.toml`, `docs_kit/SPEC_TEMPLATE.md`)
* **`config.toml`**: 파일을 열어 `default_type = "A"` 부분에 내가 선택한 알파벳(A, B, C, D 중 하나)을 적고 저장합니다.
* **`docs_kit/SPEC_TEMPLATE.md`**: 이 파일을 복사해서 프로젝트 루트에 **`SPEC.md`**라는 이름으로 저장한 뒤, 오늘 만들 핵심 기능 3가지와 예외 처리 규칙을 빈칸 채우기 방식으로 간단히 작성합니다. (처음에 `bootstrap.sh`를 실행했다면 이미 `SPEC.md`가 생성되어 있으니 열어서 내용만 채우면 됩니다.)

---

## 🏗️ Step 3. 앱 뼈대 자동 생성 및 AI 단계별 코딩

이제 직접 복잡한 초기 코드를 짤 필요 없이, 스크립트로 앱 뼈대를 만들고 AI(Claude, Cursor, ChatGPT 등)에게 프롬프트를 복사해 넣어 기능을 완성합니다.

### 1. 앱 뼈대(Scaffold) 자동 생성 (`engine/scaffold_app.sh`)
* 터미널에 아래 명령어를 입력합니다. (예: Type A를 선택했고, Next.js 웹앱으로 만들고 싶을 때)
  ```bash
  bash engine/scaffold_app.sh --target ./app --type A --stack nextjs
  ```
  * `--type`에는 `A`, `B`, `C`, `D` 중 하나를 넣습니다.
  * `--stack`에는 `nextjs`(웹 프레임워크), `fastapi`(파이썬 백엔드), `vanilla`(순수 HTML/JS) 중 편한 것을 넣습니다.
* **이 명령어가 하는 일**: `./app` 폴더 안에 바로 실행 가능한 프로젝트 기본 파일들과 핵심 계산 로직을 넣을 `core.mjs` 파일, 그리고 테스트용 파일들을 자동으로 만들어 줍니다.

### 2. 코딩 AI에게 기본 헌법 주입하기 (`AGENTS.md`)
* 사용하고 있는 AI 채팅창을 열고, 가장 먼저 **`AGENTS.md`** 파일의 내용 전체를 복사해서 붙여넣습니다.
* **왜 하나요?**: AI가 멋대로 가짜 데이터를 만들거나, 실행도 안 되는 무거운 라이브러리를 설치하는 것을 막고, 핵심 계산 로직과 화면 코드를 깔끔하게 분리해서 짜도록 강제하는 'AI 작업 수칙'입니다.
* 이때 **Step 2에서 고른 `blueprints/type_X_...md` 파일 내용**과 **`.autopilot/workspace_profile.md` 파일 내용**도 함께 AI에게 붙여넣어 주면 AI가 프로젝트 상황을 100% 이해합니다.

### 3. 단계별 프롬프트 복사해서 코딩 시키기 (`prompt_bank/step_by_step_prompts.md`)
* 이제 `step_by_step_prompts.md` 파일을 엽니다. 한 번에 "다 만들어줘"라고 하지 말고, 파일에 적힌 순서대로 프롬프트를 복사해서 AI에게 입력합니다.
  1. **Prompt 1 (문제 요약 및 타입 판정)**: 데이터 분석 결과를 바탕으로 핵심 기능 3가지를 확정하게 합니다.
  2. **Prompt 2 (1페이지 SPEC 작성)**: `SPEC.md` 문서의 내용을 완벽하게 채우도록 시킵니다.
  3. **Prompt 3 (스캐폴드 및 Core 로직 구현)**: 데이터를 읽고 계산/검증하는 핵심 함수들을 먼저 짜게 합니다.
  4. **Prompt 4 (UI 및 End-to-End 연결)**: 사용자가 보는 화면(차트, 표, 검색창, 버튼 등)을 만들고 핵심 로직과 연결하게 합니다.
  5. **Prompt 5 (결정론 검증 및 예외 방어)**: 빈 데이터나 잘못된 입력이 들어와도 프로그램이 멈추지 않도록 방어 코드를 넣게 합니다.

---

## 🔍 Step 4. 중간 점검 및 코드 무결성 자동 검증 (개발 중 수시로)

기능을 하나씩 완성할 때마다 내 코드가 제대로 작동하는지, 에러는 없는지 검증 도구를 돌려 확인합니다.

### 1. 핵심 로직 테스트 (`engine/verify_core.mjs`, `engine/deterministic_harness.mjs`)
* 터미널에 아래 명령어를 입력해 내가 만든 핵심 로직(`core.mjs`)이 정상 작동하는지 검사합니다.
  ```bash
  node engine/verify_core.mjs ./app/src/core.mjs
  ```
* 만약 내가 만든 입력값(`input.json`)과 기대하는 정답(`expected.json`)이 항상 똑같이 나오는지(결정론적 동작) 정밀하게 비교하고 싶다면 아래 명령어를 사용합니다.
  ```bash
  node engine/deterministic_harness.mjs --module ./app/src/core.mjs --input ./sample_input.json --expected ./expected_output.json
  ```

### 2. 독립 품질 감사관(Auditor) 실행 (`engine/auditor_worker.sh`, `AUDITOR_GUIDE.md`)
* 코드를 짜다 보면 놓치기 쉬운 버그나 누락된 요구사항을 제3자 시점에서 깐깐하게 점검해 주는 도구입니다.
* **`AUDITOR_GUIDE.md`** 파일을 열어 감사 기준(요구사항 충족 여부, 에러 방어 여부, 실행 가능 여부 등)을 확인합니다.
* 터미널에 아래 명령어를 실행하면 `.autopilot/audit_prompt.txt` 파일에 검수용 프롬프트가 생성됩니다. 이를 AI의 새로운 채팅창에 붙여넣으면 내 코드의 문제점을 콕 집어 리포트(`.autopilot/audit_report.md`)로 만들어 줍니다.
  ```bash
  bash engine/auditor_worker.sh --workspace . --app ./app
  ```

---

## 📝 Step 5. 최종 문서 완성 및 발표/질의응답 방어 준비

코드가 완성되었다면, 결과물의 신뢰도를 높여줄 필수 문서 3종을 완성하고 예상 질문에 대비합니다. (`bootstrap.sh`를 실행했다면 이미 루트 폴더에 복사되어 있습니다.)

### 1. 기술 의사결정 문서 작성 (`docs_kit/ARCHITECTURE_DECISIONS.md` 👉 `ARCHITECTURE_DECISIONS.md`)
* 왜 복잡한 데이터베이스 대신 가벼운 파일 방식을 썼는지, 왜 외부 AI 대신 정확한 규칙 기반 계산을 섞어 썼는지 등 **"우리가 왜 이렇게 설계했는가"**를 설명하는 문서입니다.
* 템플릿에 이미 모범적인 이유들이 적혀 있으므로, 내 프로젝트 상황에 맞게 빈칸만 살짝 다듬으면 수준 높은 기술 문서가 완성됩니다.

### 2. 실행 및 인수인계 문서 작성 (`docs_kit/HANDOFF_TEMPLATE.md` 👉 `HANDOFF.md`)
* 다른 사람(또는 평가자)이 내 프로젝트를 전달받아 그 자리에서 바로 실행해 볼 수 있도록 **설치 명령어, 실행 방법, 데모 시연 순서, 알려진 한계점**을 적어두는 문서입니다.

### 3. 날카로운 질문 방어 논리 숙지 (`docs_kit/defense_logic_guide.md`)
* 결과물을 시연하거나 발표할 때 자주 나오는 공격적인 질문들에 대비하는 필독서입니다.
* *"왜 더 화려한 최신 기술을 안 썼나요?"*, *"데이터가 100만 개로 늘어나면 어떻게 할 건가요?"*, *"AI가 거짓말(환각)을 하면 어떻게 막나요?"* 같은 질문에 당황하지 않고 논리 정연하게 답변할 수 있는 모범 스크립트가 정리되어 있으니 발표 전에 꼭 읽으세요.

---

## 🚪 Step 6. 최종 관문(Gatekeeper) 통과 및 마무리 (제출 직전)

모든 작업이 끝났습니다! 최종 제출하기 전, 필수 파일이 빠지지 않았는지, 코드 안에 `TODO` 같은 미완성 흔적이 남아있지 않은지 최종 검수 스크립트를 돌립니다.

### 1. 릴리즈 준비 상태 점검 (`engine/release_gate.py`)
* 필수 문서(`SPEC.md`, `HANDOFF.md` 등)가 모두 존재하고 내용이 충분히 채워져 있는지, 앱 폴더에 실행 스크립트가 정상적으로 있는지 검사합니다.
  ```bash
  python3 engine/release_gate.py --workspace . --app ./app
  ```

### 2. 최종 게이트키퍼 실행 (`engine/final_gatekeeper.sh`, `engine/final_gatekeeper.py`)
* 위 릴리즈 점검을 포함하여, 코드 테스트와 문서 상태까지 한 번에 종합 판정해 주는 최종 스크립트입니다. 터미널에 아래 명령어를 입력합니다.
  ```bash
  bash engine/final_gatekeeper.sh --workspace . --app ./app
  ```
* 터미널 화면 마지막에 **`OVERALL_STATUS: PASS`**가 출력되고, `.autopilot/gatekeeper_report.md` 파일에 통과 기록이 남았다면 모든 준비가 완벽히 끝난 것입니다. 만약 `FAIL`이 뜬 항목이 있다면 안내된 메시지를 보고 수정한 뒤 다시 실행하여 `PASS`를 받고 마무리하세요!