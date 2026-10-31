# 🚀 FDE-Autopilot 실전 사용자 가이드 (Step-by-Step)

이 문서는 해커톤에 처음 참가하는 사람도 `fde-autopilot`의 모든 파일을 순서대로 활용하여 **기획부터 개발, 검증, 최종 발표까지** 한 번에 끝낼 수 있도록 정리한 실전 매뉴얼입니다.

## 📊 한눈에 보는 전체 파일 요약표

본격적인 시작에 앞서, 각 폴더와 파일이 어떤 역할을 하는지 가볍게 확인하세요.

* **루트 폴더 (`/`)**: 초기 세팅(`bootstrap.sh`, `config.toml`) 및 전체 매뉴얼(`README.md`, `USER_GUIDE.md`, `PLAYBOOK_CLI.md`, `AGENTS.md`, `AUDITOR_GUIDE.md`)

* **`prompt_bank/`**: 문제 유형 분류 및 AI에게 복사해서 붙여넣을 프롬프트 모음

* **`blueprints/`**: 4가지 문제 유형별(Type A\~D) 화면/기능 상세 설계도

* **`engine/`**: 앱 뼈대 자동 생성, 데이터 분석, 코드 자동 채점 및 검증 스크립트

* **`docs_kit/`**: 기획서, 아키텍처 문서, 인계서 및 심사위원 질문 방어용 템플릿

## 🏁 Step 1. 초기 환경 세팅 및 데이터 파악 (시작 후 0\~15분)

해커톤이 시작되고 문제와 데이터가 주어지면 가장 먼저 내 컴퓨터 환경을 세팅하고 데이터를 분석합니다.

1. **기본 설명서 확인 (`README.md`, `USER_GUIDE.md`)**

   * 두 파일을 가볍게 읽고 필수 프로그램(Node.js, Python 등)이 설치되어 있는지 확인합니다.

   * 터미널 명령어가 헷갈릴 때는 작업 내내 `PLAYBOOK_CLI.md`를 옆에 띄워두고 커닝 페이퍼로 활용하세요.

2. **초기 환경 자동 구축 (`bootstrap.sh`)**

   * 터미널을 열고 아래 명령어를 실행하여 기본 폴더와 패키지를 한 번에 설치합니다.

     ```
     bash bootstrap.sh
     
     ```

3. **제공된 데이터 및 폴더 자동 분석 (`workspace_inspector.py`, `workspace_profiler.py`)**

   * 주최 측이 제공한 파일 구조와 데이터(CSV, JSON 등)가 어떤 형태인지 일일이 열어보지 않고 아래 스크립트로 한 번에 요약본을 뽑아냅니다.

     ```
     python3 engine/workspace_inspector.py
     python3 engine/workspace_profiler.py
     
     ```

## 🎯 Step 2. 문제 유형(Type A\~D) 확정 및 질문하기 (15\~45분)

주어진 해커톤 과제가 어떤 유형인지 파악하고, 애매한 요구사항을 멘토(현업 담당자)에게 질문하여 기획을 확정합니다.

1. **도메인 용어 파악 (`prompt_bank/domain_dm_playbook.md`)**

   * 제조, 공정, 백오피스 등 낯선 현업 용어가 문제에 나왔다면 이 파일을 열어 배경지식을 빠르게 습득합니다.

2. **문제 유형 판별 (`prompt_bank/typing_guide.md`)**

   * 가이드를 읽고 오늘 나온 문제가 아래 4가지 블루프린트 중 어디에 해당하는지 결정합니다.

3. **맞춤형 설계도 선택 (`blueprints/` 폴더 내 파일 택 1)**

   * **Type A (`type_a_dashboard_fdc_wafer_yield.md`)**: 불량 탐지(FDC), 수율 분석, 차트/시각화 대시보드 과제일 때 선택

   * **Type B (`type_b_validator_diff_interview_alarm.md`)**: 데이터 정합성 검증, 설정값 비교(Diff), 알람/모니터링 과제일 때 선택

   * **Type C (`type_c_policy_rag_citation_search.md`)**: 사내 규정 문서 검색(RAG), 출처(Citation) 기반 AI 챗봇 과제일 때 선택

   * **Type D (`type_d_state_machine_pm_backoffice.md`)**: 설비 점검(PM) 승인 절차, 상태 변경(State Machine), 백오피스 관리 툴 과제일 때 선택

4. **멘토에게 날카로운 질문 던지기 (`stakeholder_inquiry.md`)**

   * `prompt_bank/` 또는 `docs_kit/`에 있는 이 파일을 열어, 문제에서 빠진 예외 상황이나 채점 포인트를 멘토에게 질문해 정확한 요구사항을 확보합니다.

5. **설정 확정 및 기획서 작성 (`config.toml`, `docs_kit/SPEC_TEMPLATE.md`)**

   * **`config.toml`** 파일을 열어 오늘 선택한 타입(A\~D)과 프로젝트 기본 설정을 적어 넣습니다.

   * **`docs_kit/SPEC_TEMPLATE.md`** 양식에 맞춰 우리가 만들 핵심 기능 명세서를 빠르게 작성합니다.

## 🏗️ Step 3. 앱 뼈대 자동 생성 및 AI 코딩 (45분\~개발 완료 시까지)

바닥부터 코딩하지 않고, 스크립트로 기본 앱을 만든 뒤 AI(Cursor, Claude 등)에게 프롬프트를 순서대로 넣어 기능을 완성합니다.

1. **프로젝트 기본 뼈대 생성 (`engine/scaffold_app.sh`)**

   * 아래 명령어를 실행하면 앞서 설정한 유형에 맞는 기본 웹앱 폴더와 기초 코드가 자동으로 생성됩니다.

     ```
     bash engine/scaffold_app.sh
     
     ```

2. **AI에게 기본 규칙 주입 (`AGENTS.md`)**

   * 코딩 AI 창을 열고 가장 먼저 **`AGENTS.md`** 파일의 내용 전체와 **Step 2에서 고른 `blueprints/type_X_...md`** 파일 내용을 함께 붙여넣습니다. (AI가 해커톤 규칙과 설계도를 완벽히 이해하게 됩니다.)

3. **단계별 프롬프트로 기능 구현 (`prompt_bank/step_by_step_prompts.md`)**

   * 이 파일에 적힌 Step 1, Step 2, Step 3 프롬프트를 순서대로 복사해서 AI에게 시킵니다. 데이터 연결부터 화면 UI, 핵심 비즈니스 로직까지 막힘없이 코드가 완성됩니다.

## 🔍 Step 4. 중간 점검 및 코드 무결성 테스트 (개발 중 수시로)

기능을 하나씩 만들 때마다 내 코드가 고장 나지 않았는지, 채점 기준에 맞는지 자동 검증 도구를 돌립니다.

1. **핵심 로직 및 테스트 구동 (`verify_core.mjs`, `deterministic_harness.mjs`)**

   * 내가 만든 핵심 계산식이나 데이터 처리 로직이 항상 똑같은 정답을 내는지 테스트합니다.

     ```
     node engine/verify_core.mjs
     node engine/deterministic_harness.mjs
     
     ```

2. **자동 코드 감사 실행 (`auditor_worker.sh`, `AUDITOR_GUIDE.md`)**

   * 아래 스크립트를 돌려 보안, 예외 처리, 코딩 규칙 위반 사항이 없는지 자동 검사합니다. 에러가 뜨면 `AUDITOR_GUIDE.md`를 보고 해결 방법을 찾아 수정합니다.

     ```
     bash engine/auditor_worker.sh
     
     ```

## 📝 Step 5. 제출용 문서 포장 및 심사위원 방어 준비 (마감 1시간 전)

개발이 끝났다면 감점을 막고 가산점을 챙기기 위해 필수 산출물 문서들을 빈칸 채우기 방식으로 빠르게 완성합니다.

1. **기술 의사결정 문서 작성 (`docs_kit/ARCHITECTURE_DECISIONS.md`)**

   * 왜 이 기술과 구조를 선택했는지 템플릿의 빈칸을 채워 전문성을 어필합니다.

2. **인수인계 및 실행 가이드 작성 (`docs_kit/HANDOFF_TEMPLATE.md`)**

   * 심사위원이 내 코드를 다운받아 바로 실행해 볼 수 있도록 설치 및 구동 방법을 정리합니다.

3. **심사위원 압박 질문 방어 준비 (`docs_kit/defense_logic_guide.md`)**

   * 발표 심사 때 자주 나오는 공격 질문("데이터가 100만 개면 안 느려지나요?", "보안은 어떻게 했나요?")에 대한 모범 답안 논리를 미리 숙지합니다.

## 🚪 Step 6. 최종 게이트키퍼 통과 및 제출 (마감 20분 전)

제출 버튼을 누르기 직전, 누락된 파일이나 치명적인 버그가 없는지 최종 관문(Gatekeeper) 스크립트를 돌려 확인합니다.

1. **릴리즈 준비 상태 점검 (`engine/release_gate.py`)**

   ```
   python3 engine/release_gate.py
   
   ```

2. **최종 합격 판정 확인 (`engine/final_gatekeeper.sh`, `engine/final_gatekeeper.py`)**

   * 아래 명령어를 실행하여 모든 체크리스트에 `PASS`가 뜨는지 확인합니다.

     ```
     bash engine/final_gatekeeper.sh
     
     ```

   * 만약 `FAIL` 항목이 나오면 터미널에 안내된 원인을 수정한 뒤 다시 실행하여 **100% 통과(PASS)** 사인을 받고 최종 제출합니다!