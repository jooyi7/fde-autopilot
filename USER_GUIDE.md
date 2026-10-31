# 🧭 SK하이닉스 AI 해커톤 실전 타임라인 & 파이프라인 완벽 가이드 (`USER_GUIDE.md`)

> **💡 핵심 개념: `git clone`을 했다는 건 무슨 뜻인가요?**
> 대회장 웹 IDE는 내 PC의 파일을 마우스로 끌어다 놓는(업로드) 것이 금지되어 있습니다. 대신 웹 IDE의 터미널(검은색 명령어 창)에서 `git clone https://github.com/jooyi7/fde-autopilot.git` 명령어를 입력하면, GitHub에 있는 내 파일들이 시험장 컴퓨터(`workspace`) 안으로 **통째로 다운로드**됩니다.
> 단, 시험장 밖으로 파일을 내보내는 **`git push`는 절대 금지**되므로, 아래 `bootstrap.sh`를 실행하면 실수로도 `git push`가 작동하지 않도록 자동 잠금(Lock)이 걸립니다.

---

## ⏱️ [00:00 ~ 00:10] 1단계: 입장 직후 다운로드 및 초기 스캔 (그대로 따라 치기)

시험이 시작되고 웹 IDE가 열리면 **하단 터미널(`TERMINAL`)**을 클릭하고 아래 명령어를 순서대로 입력합니다.

```bash
# 1. 내 툴킷 다운로드 (클론)
git clone [https://github.com/jooyi7/fde-autopilot.git](https://github.com/jooyi7/fde-autopilot.git)

# 2. 초기 자동 세팅 실행 (git push 차단 + AGENTS.md 배치 + 데이터/환경 자동 스캔)
bash fde-autopilot/bootstrap.sh
```

**이 시점에 확인할 파일 2개 (왼쪽 파일 탐색기 새로고침 후 클릭):**
1. **`README.md` (과제 기본 제공 파일):** 오늘 풀어야 할 문제의 요구사항, 필수 제출 파일명, 서버 포트 번호를 확인합니다.
2. **`WORKSPACE_PROFILE.md` (`bootstrap.sh`가 방금 자동 생성한 파일):** 과제 폴더 안에 어떤 코드 파일이 있는지, CSV/JSON 데이터에 결측치(`null`)가 몇 개 있는지 1초 만에 요약되어 있습니다.

---

## ⏱️ [00:10 ~ 00:25] 2단계: 실무자 DM 질문 던지기 & 블루프린트 매칭

코드를 짜기 전에 우측 **`DMs` 메신저**의 **업무 담당자**에게 질문을 먼저 던져 숨겨진 채점 기준을 확보합니다.

* **어느 파일의 어느 부분을 쓰는가?**
  * **`fde-autopilot/docs_kit/stakeholder_inquiry.md`** (또는 `prompt_bank/domain_dm_playbook.md`) 파일을 엽니다.
  * 그 안에 적힌 **1) 결측치(Null) 처리 기준 질문, 2) 임계치 경계값(Boundary) 판정 기준 질문**을 내 과제 상황에 맞게 살짝 다듬어 업무 담당자 DM으로 전송합니다. (`Enter` 전송, 줄바꿈은 `Shift+Enter`)

* **과제 유형(Type A~D) 매칭하기 (`fde-autopilot/blueprints/` 폴더):**
  * 오늘 나온 문제가 아래 4개 중 무엇인지 확인하고 해당 파일 이름을 기억합니다.
    * **수율/센서 이상 감지 대시보드** $\rightarrow$ `blueprints/type_a_dashboard_fdc_wafer_yield.md`
    * **설정 비교(Diff) / 알람 검증기** $\rightarrow$ `blueprints/type_b_validator_diff_interview_alarm.md`
    * **사내 규정/SOP 검색 및 출처(Citation) 인용** $\rightarrow$ `blueprints/type_c_policy_rag_citation_search.md`
    * **설비 PM 일정 / 승인 워크플로우 상태 머신** $\rightarrow$ `blueprints/type_d_state_machine_pm_backoffice.md`

---

## ⏱️ [00:25 ~ 01:30] 3단계: Codex CLI 실행 및 코어 로직(80%) + UI 구현

이제 터미널에서 대회 내장 AI인 **`codex`**를 깨워 일을 시킵니다.

```bash
# 1. 터미널에 codex 입력 후 엔터 (폴더 신뢰 여부를 물으면 승인)
codex

# 2. codex 창 안에서 모델 확인 및 변경 (Astra 절대 금지! Sol 6.1 또는 Terra 5.6 선택)
/status
/model
```

**Codex에게 입력할 프롬프트 순서 (`fde-autopilot/prompt_bank/step_by_step_prompts.md` 참고):**

1. **[1차 지시 - 설계 및 결정론 코어 구현]:**
   > "`README.md`와 `WORKSPACE_PROFILE.md`, 그리고 `AGENTS.md`의 80/20 원칙을 읽고, `fde-autopilot/blueprints/type_X_...md` 구조에 맞춰 먼저 수치 계산과 판정을 담당하는 결정론적 코어 모듈(`src/core/`)과 데이터 파서를 작성해 줘. 결측치(`null`, `NaN`) 방어 로직을 반드시 포함해."
2. **[중간 점검 - 새 터미널(`+` 버튼)을 열어서 실행]:**
   * 만약 기본 앱 뼈대가 아예 없는 백지 과제라면: `bash fde-autopilot/engine/scaffold_app.sh` 활용.
   * 코어 로직 검증: `node fde-autopilot/engine/verify_core.mjs` 실행.
3. **[2차 지시 - DM 답변 반영 및 웹 UI/서버 연결]:**
   > "업무 담당자 DM에서 확인한 기준([DM 답변 내용 요약])을 코어 판정 로직에 반영해 줘. 그리고 `src/ai/` 리포터(API 실패 시 결정론적 Fallback 포함)와 대시보드 UI를 연결한 뒤, 서버가 반드시 `0.0.0.0` 호스트에 바인딩되도록 설정해 줘."

---

## ⏱️ [01:30 ~ 02:20] 4단계: 내장 Browser 미리보기 검증 (서버 유지 필수!)

1. **서버 전용 터미널 분리:** 터미널에서 `+` 버튼을 눌러 **새 터미널 탭**을 열고 서버를 실행합니다 (예: `npm run dev -- --host 0.0.0.0` 또는 `python3 app.py`).
   * ⚠️ **주의:** 서버가 돌아가는 터미널 탭은 **절대 닫거나 `Ctrl+C`를 누르지 마세요!** 닫으면 서버가 꺼집니다.
2. **내장 Browser 연결:**
   * 왼쪽 도구 모음에서 **지구본 모양(Browser)** 아이콘을 클릭합니다.
   * `PORT` 입력란에 터미널에 뜬 실제 포트 번호(예: `3000`, `5173`, `8000` 등)를 적고 오른쪽 **새로고침(원형 화살표)** 버튼을 누릅니다.
   * 화면이 뜨면 버튼 클릭, 필터링, 이상 데이터 입력 등을 직접 해보며 에러가 없는지 확인합니다.

---

## ⏱️ [02:20 ~ 02:50] 5단계: 제출 필수 문서 작성 & 최종 감사(Gatekeeper) 돌리기

가이드라인 6장에 따라 **계획/설계 문서(판단과 근거, 검증 결과, 남은 한계)** 점수를 챙기고 최종 감사를 수행합니다.

* **어느 파일을 쓰는가?**
  * 1단계에서 루트에 자동 복사된 **`SOLUTION_NOTES.md`** (원본: `docs_kit/ARCHITECTURE_DECISIONS.md`) 또는 **과제 `README.md`에서 요구한 정확한 문서 파일명**을 엽니다.
  * 만약 Codex 세션이 너무 길어져 느려졌거나 정리가 필요하면 `docs_kit/HANDOFF_TEMPLATE.md` 양식에 맞춰 Codex에게 *"지금까지 구현한 설계 판단과 근거, 실무자 DM 반영 사항, 테스트 검증 결과, 남은 한계점을 정리해서 제출 문서에 작성해 줘"*라고 지시합니다.

* **최종 감사 스크립트 실행 (제출 15분 전 필수):**
  서버가 아닌 다른 터미널 탭에서 아래 명령어를 실행합니다.
  ```bash
  bash fde-autopilot/engine/auditor_worker.sh
  ```
  * `localhost` 단독 바인딩 실수, 빈 마크다운 문서, 하드코딩된 키가 없는지 자동으로 검사해 줍니다.
  * 모든 파일 탭에서 **`Ctrl+S` (Mac은 `Cmd+S`)**를 눌러 저장 상태가 **`저장됨`**인지 확인합니다.

---

## ⏱️ [02:50 ~ 03:00 + 30분] 6단계: 제출 확정 및 후속 서술형(5문항) 완벽 방어

> ⚠️ **초비상 체크:** 우측 상단 검은색 **`제출하고 문제풀기`** 버튼을 누르고 제출을 확정하면, **그 순간부터 코드를 다시 볼 수 없고, AI도 쓸 수 없으며, 복사/붙여넣기도 불가능합니다!**

**제출 확정 버튼 누르기 직전 3분 동안 할 일:**
1. **`fde-autopilot/docs_kit/defense_logic_guide.md`** (또는 `prompt_bank/typing_guide.md`) 파일을 엽니다.
2. 종이나 머릿속에 내가 오늘 만든 **① 핵심 파일명 2개, ② 핵심 판정 함수명 2개, ③ 결측치/예외 처리 방식 1개, ④ DM으로 확인한 규칙 1개**를 확실히 기억합니다.
3. **`defense_logic_guide.md`의 3문장 답변 공식**을 숙지한 뒤 **`제출물 확정하고 문제풀기`**를 눌러 문항당 5분씩 직접 타이핑하여 답변하고 퇴장합니다.