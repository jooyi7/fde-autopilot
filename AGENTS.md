# FDE Autopilot Master Agent Rules (80/20 Deterministic-First & Dual-Terminal Protocol)

너는 SK하이닉스 FDE(Forward Deployed Engineer) 실기 과제를 수행하는 코딩 에이전트다. 모든 분석, 설계, 코드 작성, 검증 시 아래 절대 원칙을 준수한다.

---

## 1. 아키텍처 4대 레이어 물리적 분리 (80/20 법칙)
- `/src/data` : 입력 파싱, 결측치/센티널값(`-999`, `null`, `NaN`, 빈 문자열) 안전 정제(`sanitizeAndParseInput`), **3종 골든 샘플(정상 `normal` / 경고 `warning` / 위반·불량 `violation`)** 프리셋 데이터 제공.
- `/src/core` : **결정론 코어 (80%)**. 모든 수치 계산, 정규식 필터링, 임계치(3-Sigma UCL/LCL, 등호 `>=` vs `>`) 판정, 상태 머신 전이는 **100% 고정된 순수 함수(Pure Function)**로 작성한다. 절대 LLM에게 산술 연산이나 조건 판정을 맡기지 않는다.
- `/src/ai` : **유연한 해석 및 리포팅 (20%)**. `/src/core`가 산출한 결정론적 JSON 판정 결과를 입력받아 자연어 요약, 작업자 조치 가이드(SOP), 피드백 문장만 생성한다.
- `/src/components` : 화면 최상단 **3종 골든 샘플 원클릭 입력 버튼**, 핵심 KPI 카드, 상태 배지(`NORMAL`/`WARNING`/`VIOLATION`), 판정 근거 및 AI 리포트 UI.

---

## 2. 필수 생존 장치 (Fallback & Network & Git Invariants)
1. **0.1초 무중단 Fallback 필수**: LLM 호출 실패, 타임아웃(3초 초과), API 키 부재 시 에러로 멈추지 않고 `/src/core`의 판정 수치를 기반으로 사전 정의된 표준 템플릿 리포트를 즉시 반환한다(`generateInsightWithFallback`).
2. **웹 서버 `0.0.0.0` 바인딩 필수**: 모든 웹 서버(Vite, Next, Express, FastAPI, Flask 등)는 반드시 `--host 0.0.0.0`으로 바인딩하여 Cofa 플랫폼 내장 Browser 미리보기 도구에서 즉시 연결되게 한다 (`localhost` 단독 바인딩 절대 금지).
3. **개인 API 키 하드코딩 금지**: 코드 내에 개인 API 키(`sk-...` 등)를 절대 평문으로 넣지 않으며, 환경 변수 또는 Fallback 모드로 동작하게 한다.
4. **기존 Git 히스토리 훼손 금지**: 시험 중 `git commit`, `git reset`, `git clean` 등으로 기본 제공된 베이스라인 커밋을 덮어쓰거나 날리지 않는다. 임시 스캔 파일(`.fde_data_profile.md` 등)은 제출 전 정리하거나 `.git/info/exclude`로 격리한다.

---

## 3. 듀얼 터미널 & 모델 운용 수칙 (토큰 비용 통제 및 컨텍스트 위생)
시험 환경의 토큰 사용량 추적 및 컨텍스트 오염(Constraint Drift)을 방지하기 위해 다음 워크플로우를 준수한다 (`Astra` 모델 사용은 엄격히 금지하며, 환경에서 제공되는 `Sol 6.1` 또는 `Luna 6` 모델을 활용한다):
- **터미널 1 (Builder / Architect)**:
  - `SPEC.md`(서면 합의서 및 구현 좌표 매핑), `/src/core` 결정론 로직, `/src/ai` Fallback 래퍼, `/src/components` UI 구현 및 `HANDOFF.md` 작성을 수행한다.
  - 대용량 CSV/JSON/로그 원문을 프롬프트 창에 통째로 출력(`cat`)하지 말고, 반드시 `python3 /tmp/fde-kit/engine/workspace_profiler.py`가 요약한 `.fde_data_profile.md`만 읽고 설계한다.
  - 1개 레이어(예: `src/core/rules.js`) 구현 및 하네스 검증이 완료될 때마다, 불필요한 에러 로그가 쌓였다면 `SPEC.md`에 진행 상태를 기록한 뒤 `/clear`로 컨텍스트를 가볍게 유지한다.
- **터미널 2 (Independent Auditor & Runner)**:
  - 웹 서버(`0.0.0.0`) 상시 구동 및 `node /tmp/fde-kit/engine/deterministic_harness.mjs`, `python3 /tmp/fde-kit/engine/final_gatekeeper.py` 실행을 전담한다.
  - 제출 20분 전 독립 감사관 세션으로 기동하여 문서(`SPEC.md`, `HANDOFF.md`)에 적힌 `[구현 좌표: 파일경로 - 함수명()]`과 실제 소스코드 간의 불일치(Drift)를 교차 검증한다.

---

## 4. 후속 서술형 평가(6문항 × 5분, 복붙 불가) 대비 코드 명확성 원칙
- 제출 확정 후 진행되는 후속 서술형 문제는 AI 사용과 복사·붙여넣기(`Ctrl+C/V`)가 전면 차단되며 제출물과 작업 기록을 기반으로 출제된다.
- 따라서 모든 핵심 함수명(`sanitizeAndParseInput`, `evaluateCoreRules`, `generateInsightWithFallback`)은 직관적이고 일관되게 명명하며, 오버엔지니어링을 배제하고 응시자가 4문장으로 동작 원리와 한계점을 즉시 타이핑할 수 있는 명쾌한 구조만 사용한다.
