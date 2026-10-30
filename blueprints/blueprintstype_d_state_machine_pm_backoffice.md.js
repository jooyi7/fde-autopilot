// ============================================================================
// [Blueprint Type D] 설비 PM 잔여수명(RUL) 산출 & 상태 머신(State Machine) 결재 엔진
// 적용 대상: Case 04 (어드민 승인), Case 06 (워크플로우 파이프라인), Case 11 (설비 PM 관리)
// ============================================================================

const VALID_TRANSITIONS = {
  DRAFT: ["PENDING"],
  PENDING: ["APPROVED", "HOLD", "REJECTED"],
  HOLD: ["PENDING", "REJECTED"],
  APPROVED: ["COMPLETED"],
  REJECTED: []
};

export const GOLDEN_SAMPLES = {
  normal: {
    workOrderId: "WO-PM-101",
    partName: "Etch_Focus_Ring_#1",
    maxHours: 500,
    usedHours: 220,
    dailyRunHours: 20,
    currentState: "PENDING",
    targetState: "APPROVED",
    engineerNote: "정기 예방 점검 승인 요청 (마모율 양호)"
  },
  warning: {
    workOrderId: "WO-PM-202",
    partName: "CVD_ShowerHead_#4",
    maxHours: 500,
    usedHours: 445,
    dailyRunHours: 22,
    currentState: "PENDING",
    targetState: "APPROVED",
    engineerNote: "교체 임계치(85%) 돌파: 2일 내 부품 수급 및 PM 슬롯 확보 필수"
  },
  violation: {
    workOrderId: "WO-PM-303",
    partName: "ESC_Electrostatic_Chuck_#2",
    maxHours: 500,
    usedHours: 530,
    dailyRunHours: 24,
    currentState: "REJECTED",
    targetState: "APPROVED",
    engineerNote: ""
  }
};

export function evaluateCoreRules(item) {
  if (!item || typeof item !== "object") {
    return { status: "VIOLATION", score: 0, transitionAllowed: false, reason: "Invalid WorkOrder Object" };
  }

  const maxH = Math.max(1, Number(item.maxHours) || 500);
  const usedH = Math.max(0, Number(item.usedHours) || 0);
  const dailyH = Math.max(1, Number(item.dailyRunHours) || 24);

  // 1. 소모품 마모율(Wear Rate) 및 잔여 수명(RUL D-Day) 계산
  const wearRate = Number(((usedH / maxH) * 100).toFixed(1));
  const remainingHours = Math.max(0, maxH - usedH);
  const dDay = Math.floor(remainingHours / dailyH);

  // 2. 상태 머신(State Machine) 전이 유효성 검사
  const allowedNext = VALID_TRANSITIONS[item.currentState] || [];
  const transitionAllowed = allowedNext.includes(item.targetState);
  const hasNote = Boolean(item.engineerNote && String(item.engineerNote).trim().length >= 5);

  const violations = [];
  if (!transitionAllowed) {
    violations.push(`불가능한 상태 전이 시도: [${item.currentState}] ➔ [${item.targetState}]`);
  }
  if (!hasNote) {
    violations.push("필수 항목 누락: 엔지니어 점검 사유(engineerNote) 5자 이상 기재 필수");
  }
  if (wearRate >= 100) {
    violations.push(`소모품 수명 한계 초과 (${wearRate}%, D-Day: 0일) - 라인 즉시 가동 중지 필요`);
  }

  let status = "NORMAL";
  if (violations.length > 0) status = "VIOLATION";
  else if (wearRate >= 85 || dDay <= 3) status = "WARNING";

  const score = Math.max(0, Math.round(100 - Math.max(0, wearRate - 70) * 1.5 - violations.length * 30));

  return {
    status,
    score,
    workOrderId: item.workOrderId,
    partName: item.partName,
    wearRate,
    remainingHours,
    dDay,
    transitionAllowed: transitionAllowed && hasNote,
    violations
  };
}