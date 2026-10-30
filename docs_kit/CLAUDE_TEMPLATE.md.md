# ⚙️ CLAUDE.md — FDE 오케스트레이션 및 엔지니어링 제어 원칙

## 1. 결정론 코어 우선 원칙 (Deterministic Core 80% Rule)
- 모든 산술 계산(합계, 평균, 수율, 마모율, 감점), 임계치 비교(3-Sigma UCL/LCL, Spec Delta), 정규식 패턴 매칭, 상태 전이(State Machine) 검증은 **100% 고정된 순수 함수(`src/core/rules.js`)**로만 처리한다.
- LLM에게 숫자 계산이나 조건부 Pass/Fail 판정을 절대 위임하지 않는다.

## 2. AI 역할 제한 및 구조화 원칙 (Flexible AI 20% Rule)
- AI 모듈(`src/ai/reporter.js`)은 오직 결정론 코어가 확정한 JSON 판정 결과(`status`, `score`, `metrics`, `violations`)를 입력받아, 현업 담당자가 즉시 활용할 수 있는 **요약 브리핑, 원인 추론, 1차 표준 조치 가이드(SOP)** 문장만 생성한다.

## 3. FDE 세 가지 왜 (The Three Whys)
1. **진짜 데이터 원천(Source of Truth)은 무엇인가?**
   - 현장 설비/업무 로그 파일 및 표준 스펙 정의서(`src/data/samples.js` 및 입력 파서)가 유일한 원천이며, 가공 전 원본 수치와 정제 후 수치를 분리 보존한다.
2. **이 문제를 안 풀면 무엇이 가장 비싼가(Cost of Inaction)?**
   - 임계치 초과나 규정 위반을 제때 걸러내지 못해 발생하는 사후 품질 사고(라인 정지, 재작업, 컴플라이언스 페널티)와 숙련 엔지니어의 단순 반복 검토 시간 낭비가 가장 큰 비용이다.
3. **내가 떠난 뒤 누가 어떻게 유지보수하는가(Maintainability)?**
   - AI 프롬프트를 모르는 현장 엔지니어라도 `src/core/rules.js` 상단의 **임계치 상수(Threshold Config) 객체만 수정**하면 즉시 판정 기준을 변경할 수 있도록 비즈니스 규칙과 UI/AI 코드를 완전히 분리했다.

## 4. 무중단 Fallback 아키텍처 (Resilience Principle)
- 외부 LLM API 지연, 타임아웃, 호출 실패 시 애플리케이션이 크래시되거나 빈 화면을 보이지 않고, 즉시 결정론 코어의 수치 판정 결과와 표준 SOP 템플릿을 결합한 **결정론 기반 Fallback 리포트**를 반환한다.

## 5. 실행 환경 및 보안 원칙
- 개발 서버는 반드시 `0.0.0.0`에 바인딩하여 플랫폼 내장 Browser 미리보기에서 즉시 검증 가능하게 유지한다.
- 개인 API 키를 코드에 하드코딩하지 않으며, 모든 예외 입력(`null`, `undefined`, 빈 문자열)은 파서와 코어 입구에서 안전하게 기본값으로 치환한다.