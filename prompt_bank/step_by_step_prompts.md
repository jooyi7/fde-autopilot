# 🎯 FDE 타임라인별 실전 프롬프트 뱅크 (복사-붙여넣기 전용)

---

## [00:02] 실무자 에이전트(DM) 인터뷰 질문 2연타
> 우측 DM 메신저에서 `업무 담당자` 선택 후 전송 (Shift+Enter로 줄바꿈, Enter로 전송).
> 주의: 처음 3분간 "AI", "자동화", "LLM" 같은 해법 단어 절대 사용 금지!

### [1차 질문 전송 (에피소드 & 임시 대처법 발굴)]
안녕하세요 담당자님! 과제 요구사항을 정확히 파악하고 현업에 꼭 맞는 도구를 설계하기 위해 먼저 여쭙고 싶습니다.
최근 이 업무를 처리하시면서 가장 시간이 많이 소요되었거나 아찔했던 구체적인 문제 사례(에피소드)가 있었을까요? 그리고 현재는 그 문제를 어떤 방식(수작업, 엑셀 정리, 육안 확인 등)으로 임시 대처(Workaround)하고 계신지 궁금합니다.

### [답변 받은 후 2차 질문 전송 (정량 지표 & 예외 경계 확정)]
상세히 설명해주셔서 감사합니다. 그렇다면 이번 도구가 현장에 도입되었을 때 어떤 숫자(처리 시간 단축, 불량/오류 탐지율, 수율 등)가 어느 정도 수준으로 개선되어야 현업에서 "실질적인 성공이다"라고 판단하실 수 있을까요?
아울러 현장에서 절대 놓치면 안 되는 치명적인 예외 케이스나, 반대로 이번 1차 버전에서는 과감히 제외해도 무방한 부가 기능이 있다면 알려주시면 그 기준에 맞춰 정확히 구현하겠습니다!

---

## [Step 1: 00:05] SPEC.md 및 CLAUDE.md 선행 생성 프롬프트 (터미널 1번 Codex)
> 아래 내용을 통째로 복사하여 터미널 1번 Codex 입력창에 붙여넣고 Enter를 누르세요.

현재 작업 폴더의 README.md와 .fde_data_profile.md(데이터 자동 스캔 결과), 그리고 /tmp/fde-kit/docs_kit/ 폴더 안의 템플릿 구조를 참고해서 코딩을 시작하기 전에 아래 2개의 문서를 루트 경로에 먼저 생성해 줘. 아직 애플리케이션 코드는 작성하지 마.

1. SPEC.md (서면 합의서):
- 현업 비즈니스 문제 정의 및 병목 원인
- 단 하나의 핵심 해결 과제 (간극/Delta 집중)
- 정량적 성공 기준 표 (측정 지표, 현재값, 목표치, 검증 방법)
- In-Scope (이번에 반드시 구현할 핵심 기능 5가지 및 예정 [구현 좌표: 파일명 - 함수명()] 자리 표시) vs Out-of-Scope (제외할 부가 기능: 로그인/권한 등)
- 7단계 진행 상태 트래커 ([STATE-1: 발굴] -> [STATE-2: 서면합의] -> [STATE-3: 스캐폴딩] -> [STATE-4: E2E v0] -> [STATE-5: 중간검증] -> [STATE-6: 수용확인/핸드오프] -> [STATE-7: 제출의식])

2. CLAUDE.md (FDE 오케스트레이션 원칙):
- 결정론 코어(80%) 원칙: 모든 수치 계산, 임계치(UCL/LCL) 판정, 정규식 필터링, 상태 전이는 100% 고정된 순수 함수(/src/core/rules.js)로 작성한다.
- AI 역할 제한(20%) 원칙: LLM(/src/ai/reporter.js)은 고정 코드가 판정한 JSON 결과를 바탕으로 자연어 해석, 피드백, 조치 가이드 초안을 생성하는 데만 사용한다.
- 세 가지 왜 (진짜 데이터 원천이 무엇인지, 안 풀면 무엇이 비싼지, 내가 떠난 뒤 누가 유지보수하는지) 명문화
- 무중단 Fallback 원칙: LLM API 호출 지연·실패 시 서비스가 멈추지 않고 결정론 코어의 기본 판정 리포트를 즉시 반환한다.
- 네트워크 원칙: 서버는 반드시 0.0.0.0에 바인딩하며 개인 API 키를 하드코딩하지 않는다.

---

## [Step 2: 00:15] 4-Layer 스캐폴딩 & 0.0.0.0 E2E v0 관통 프롬프트 (터미널 1번 Codex)
> 오늘 과제 유형에 맞는 블루프린트 파일명(type_a / type_b / type_c / type_d 중 택1)을 확인한 뒤 아래 프롬프트를 투입하세요.
> - Type A (센서 시계열/웨이퍼맵/수율/통계 대시보드): type_a_dashboard_fdc_wafer_yield.md
> - Type B (레시피 스펙 Diff 비교/인터뷰 금기어/이상탐지/알람 SOP): type_b_validator_diff_interview_alarm.md
> - Type C (사내 규정/매뉴얼 문서 검색 & 출처 인용 RAG): type_c_policy_rag_citation_search.md
> - Type D (설비 PM 잔여수명 계산 & 상태 머신 결재/백오피스): type_d_state_machine_pm_backoffice.md

이제 SPEC.md와 CLAUDE.md의 원칙, 그리고 /tmp/fde-kit/blueprints/ 폴더 내 이번 과제에 해당하는 블루프린트 코드 구조와 .fde_data_profile.md의 실제 데이터 스키마를 결합하여 [STATE-3: 스캐폴딩] 및 [STATE-4: E2E v0] 단계를 진행해 줘.

1. 아키텍처 4대 레이어 물리적 분리 구현:
- src/data/samples.js : 과제 데이터 스키마에 맞춘 3종 골든 샘플(normal, warning, violation) 및 결측치/Null 안전 파서(sanitizeAndParseInput)
- src/core/rules.js : 정규식 필터링, 임계치(UCL/LCL 또는 스펙 오차) 판정, 점수/수율/통계 계산을 담당하는 100% 결정론적 순수 함수(evaluateCoreRules)
- src/ai/reporter.js : 코어의 판정 결과를 받아 자연어 요약·조치 가이드를 생성하는 함수(generateInsightWithFallback - 에러나 타임아웃 시 0.1초 내로 코어 수치 기반 표준 안전장치 리포트를 반환하는 Fallback 필수 포함)
- src/components/Dashboard.jsx : 화면 최상단에 평가자가 클릭 한 번으로 테스트할 수 있는 3종 골든 샘플 버튼([정상 샘플 입력], [경고(임계치) 샘플 입력], [위반/불량 샘플 입력]), 핵심 KPI 요약 카드, 시각화 차트/테이블, 판정 근거 및 AI 리포트 뷰어

2. E2E v0 우선 관통 및 0.0.0.0 서버 실행:
- 상단 프리셋 버튼 3개를 클릭하거나 데이터를 입력해 실행 버튼을 누르면 즉시 결정론 코어 판정과 리포트가 화면에 렌더링되도록 End-to-End 파이프라인을 연결해 줘.
- 웹 서버는 플랫폼 내 Browser 미리보기 도구에서 바로 열리도록 반드시 host 0.0.0.0으로 바인딩해서 실행하고, 리스닝 중인 실제 포트 번호를 알려줘.

---

## [Step 3-A: 00:35] 결정론 코어 정밀 구현 & 하네스 검증 프롬프트 (터미널 1번 Codex)

[STATE-5: 중간검증]의 첫 번째 분해 작업이다. UI나 AI 호출부는 건드리지 말고 오직 src/core/rules.js의 결정론적 판정·계산 로직만 완벽하게 고도화해 줘.
1. README.md, .fde_data_profile.md, SPEC.md에 정의된 모든 비즈니스 규칙(임계치, 수식, 상태 전이, 예외 처리)을 고정 코드로 정확히 구현해 줘.
2. 빈 문자열(""), null, undefined, NaN, 빈 배열이 들어와도 절대 크래시되지 않고 안전하게 예외 판정 객체를 반환하도록 방어 로직을 완벽히 넣어 줘.
3. 구현 직후 node /tmp/fde-kit/engine/deterministic_harness.mjs 명령어를 실행해서 정상 케이스, 경계값(Edge case), 위반 케이스, Null 방어, AI Fallback 5개 시나리오가 모두 PASS하는지 터미널에 증명해 줘.

---

## [Step 3-B: 00:55] AI 파이프라인 결합 & SPEC.md 증거 좌표 매핑 프롬프트 (터미널 1번 Codex)

검증된 src/core/rules.js의 출력값을 src/ai/reporter.js 및 프론트엔드 UI(src/components/Dashboard.jsx)와 완전히 결합해 줘.
1. 판정 상태(NORMAL=초록, WARNING=노랑, VIOLATION=빨강) 배지와 핵심 수치, 위반 사유, AI 조치 가이드(및 Fallback 작동 여부)가 화면에서 한눈에 보이도록 시각적 완성도를 높여 줘.
2. 작업 완료 후 SPEC.md 파일을 열어서 In-Scope의 각 요구사항 항목 옆에 실제로 구현된 파일 경로와 핵심 함수명(예: [구현 좌표: src/core/rules.js - evaluateCoreRules()])을 정확하게 매핑해서 업데이트해 줘.

---

## [Step 4-A: 01:15] HANDOFF.md 생성 프롬프트 (터미널 1번 Codex)

이제 [STATE-6: 수용확인 및 핸드오프] 단계다. /tmp/fde-kit/docs_kit/HANDOFF_TEMPLATE.md의 구조를 참고하여 현재 우리 프로젝트의 실제 파일명과 함수명에 맞춘 HANDOFF.md 파일을 루트 경로에 생성해 줘. 반드시 아래 4가지를 상세히 포함해야 해:
1. 전체 아키텍처 및 데이터 흐름도 (입력 -> Data 파서 -> Deterministic Core 80% -> AI Reporter & Fallback 20% -> UI 렌더링)
2. 완료된 핵심 기능 및 실제 코드 증거 좌표 표 (파일 경로 + 함수명 + 검증 결과)
3. 핵심 엔지니어링 의사결정 근거 (왜 산술/규칙 판정과 AI 요약을 분리했는지, 왜 3종 골든 샘플과 Fallback을 두었는지)
4. 사후 확인 문제 대비 3단계 기술 리스크 분석:
   - (약점 지목): 실제 구현된 파일명(src/core/rules.js, src/ai/reporter.js 등)과 함수명을 정확히 지목하여 구체적인 기술적 한계점 3가지 명시 (대용량 입력 시 인메모리 동기 순회 병목, 외부 LLM API 장애 시 재시도 큐 부재 등)
   - (위험 파급): 해당 약점이 실제 현업/공정 현장에서 깨졌을 때 발생하는 비즈니스적·시스템적 파급 위험 설명
   - (검증 및 개선 계획): 더미 부하 스크립트를 통한 정량적 임계치 계측(검증) 방법과 단기(해시 캐싱/로컬 스토리지 영속화)·장기(Web Worker 비동기 분리/메시지 큐 도입) 개선 계획 제시

---

## [Step 4-B: 01:25] 터미널 2번 독립 감사관(Auditor) 교차 검증 프롬프트
> 새 터미널(2번)을 열고 bash /tmp/fde-kit/engine/auditor_worker.sh 를 먼저 실행한 뒤, codex 를 켜고 아래 프롬프트를 입력합니다.

너는 메인 개발 세션과 분리된 독립 교차 검증 감사관(Auditor)이다. /tmp/fde-kit/AUDITOR_GUIDE.md 및 방금 생성된 .fde_audit_report.md를 참고하여 현재 워크스페이스의 README.md, SPEC.md, CLAUDE.md, HANDOFF.md와 실제 src/ 하위 소스코드를 대조하여 감사해 줘.
1. 문서에 적힌 요구사항이나 [구현 좌표] 중 실제 코드의 파일명·함수명과 다르거나 누락(Drift)된 부분을 찾아 즉시 일치시켜 줘.
2. 사용자가 빈 값, 특수문자, 깨진 JSON/CSV 데이터를 넣었을 때 화면이 깨지는(Runtime Error) 취약 지점을 찾아 즉시 방어 코드(try-catch, Optional Chaining)를 패치해 줘.
3. SPEC.md의 7단계 진행 상태 트래커 체크박스를 모두 [x] 완료 상태로 업데이트하고 임시 스캔 파일(.fde_data_profile.md, .fde_audit_report.md)을 정리해 줘.
