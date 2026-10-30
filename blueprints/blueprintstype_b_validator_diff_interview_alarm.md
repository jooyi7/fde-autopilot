// ============================================================================
// [Blueprint Type B] 레시피 스펙 Diff 검증기 & 규정 위반/이상 탐지 & 알람 SOP 엔진
// 적용 대상: Case 01 (인터뷰 코칭), Case 05 (이상거래), Case 09 (레시피 검증), Case 12 (알람 SOP)
// ============================================================================

export const GOLDEN_SAMPLES = {
  normal: {
    scenario: "정상 레시피 & 준수 텍스트",
    alarmCode: "ALM-100",
    utterance: "오늘 공정 표준 작업 절차서를 준수하여 챔버 점검을 완료했습니다.",
    params: [
      { name: "RF_Power(W)", spec: 500, tol: 15, actual: 503 },
      { name: "Chamber_Press(mTorr)", spec: 40, tol: 4, actual: 39.5 },
      { name: "Gas_Ar_Flow(sccm)", spec: 120, tol: 10, actual: 122 }
    ]
  },
  warning: {
    scenario: "경고 샘플 (마진 부족 80% 근접 & 주의 발언)",
    alarmCode: "ALM-205",
    utterance: "일정이 조금 촉박해서 심판이나 관리자 판정이 아쉽지만 진행하겠습니다.",
    params: [
      { name: "RF_Power(W)", spec: 500, tol: 15, actual: 513.5 },
      { name: "Chamber_Press(mTorr)", spec: 40, tol: 4, actual: 43.6 },
      { name: "Gas_Ar_Flow(sccm)", spec: 120, tol: 10, actual: 128.5 }
    ]
  },
  violation: {
    scenario: "위반/불량 샘플 (스펙 초과 이탈 & 금기어/Fatal 알람)",
    alarmCode: "ALM-999",
    utterance: "상대 수준이 낮아서 대충 해도 되고, 스폰서 장비도 최악이라 임의로 값을 바꿨습니다.",
    params: [
      { name: "RF_Power(W)", spec: 500, tol: 15, actual: 545.0 },
      { name: "Chamber_Press(mTorr)", spec: 40, tol: 4, actual: 29.0 },
      { name: "Gas_Ar_Flow(sccm)", spec: 120, tol: 10, actual: 155.0 }
    ]
  }
};

const ALARM_SOP_DB = {
  "ALM-100": { severity: "INFO", action: "정상 캘리브레이션 알림: 현 공정 가동 유지" },
  "ALM-205": { severity: "WARN", action: "진공 배기 밸브 압력 흔들림: 오링(O-Ring) 리크 점검 요망" },
  "ALM-999": { severity: "FATAL", action: "RF 제너레이터 인터록 트립: 즉시 E-Stop 후 안전 엔지니어 호출" }
};

const FORBIDDEN_PATTERNS = [
  { id: "RULE-TEXT-01", label: "스폰서/장비 비하 및 임의 조작", regex: /(스폰서.*최악|임의로.*바꿨|불매)/g, penalty: 40 },
  { id: "RULE-TEXT-02", label: "태업/상대 비하 발언", regex: /(수준.*낮|대충.*해도)/g, penalty: 30 },
  { id: "RULE-TEXT-03", label: "판정/절차 불만 표출", regex: /(판정이.*아쉽|촉박해서)/g, penalty: 15 }
];

export function evaluateCoreRules(input) {
  if (!input || typeof input !== "object") {
    return { status: "VIOLATION", score: 0, diffs: [], textHits: [], sop: ALARM_SOP_DB["ALM-999"], reason: "Empty Input" };
  }

  // 1. 레시피 파라미터 Spec vs Actual 오차(Delta) 계산
  const rawParams = Array.isArray(input.params) ? input.params : [];
  const diffs = rawParams.map((p) => {
    const spec = Number(p.spec) || 0;
    const tol = Math.max(0.0001, Number(p.tol) || 1);
    const actual = Number(p.actual) || 0;
    const delta = Number(Math.abs(actual - spec).toFixed(2));
    const marginRatio = Number(((delta / tol) * 100).toFixed(1));
    const judge = delta > tol ? "OUT_OF_SPEC" : marginRatio >= 80 ? "MARGIN_LOW" : "OK";
    return { name: String(p.name || "Param"), spec, tol, actual, delta, marginRatio, judge };
  });

  // 2. 텍스트 정규식 금기어 탐지
  const text = String(input.utterance || "");
  const textHits = [];
  let penaltySum = 0;
  FORBIDDEN_PATTERNS.forEach((rule) => {
    const m = text.match(rule.regex);
    if (m) {
      penaltySum += rule.penalty;
      textHits.push({ id: rule.id, label: rule.label, matched: m[0], penalty: rule.penalty });
    }
  });

  // 3. 알람 코드 매칭
  const sop = ALARM_SOP_DB[input.alarmCode] || { severity: "WARN", action: "미등록 알람 코드: 표준 매뉴얼 확인 및 선임 보고" };

  const outCount = diffs.filter((d) => d.judge === "OUT_OF_SPEC").length;
  const lowCount = diffs.filter((d) => d.judge === "MARGIN_LOW").length;

  let status = "NORMAL";
  if (outCount > 0 || penaltySum >= 30 || sop.severity === "FATAL") status = "VIOLATION";
  else if (lowCount > 0 || penaltySum > 0 || sop.severity === "WARN") status = "WARNING";

  const score = Math.max(0, 100 - outCount * 25 - lowCount * 10 - penaltySum);
  return { status, score, diffs, textHits, sop, alarmCode: input.alarmCode || "N/A" };
}

export async function generateInsightWithFallback(coreResult) {
  const outParams = coreResult.diffs.filter((d) => d.judge !== "OK").map((d) => `${d.name}(오차 ${d.delta})`).join(", ");
  const textIssues = coreResult.textHits.map((t) => t.label).join(", ");
  return {
    source: "DETERMINISTIC_FALLBACK",
    text: `[검증 리포트 - ${coreResult.status}] 종합 점수 ${coreResult.score}점. ` +
          `파라미터 점검: ${outParams || "전 항목 정상"}. ` +
          `텍스트 규정 점검: ${textIssues || "위반 표현 없음"}. ` +
          `알람(${coreResult.alarmCode}) 표준 조치: ${coreResult.sop?.action}`
  };
}
