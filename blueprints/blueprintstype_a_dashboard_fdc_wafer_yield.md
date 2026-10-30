// ============================================================================
// [Blueprint Type A] 반도체 FDC 센서 시계열 & 웨이퍼 맵 & 공정 수율 통합 대시보드
// 적용 대상: Case 02 (통계/VOC), Case 07 (Wafer Map), Case 08 (FDC Alert), Case 10 (Yield)
// ============================================================================

// ----------------------------------------------------------------------------
// 1. [src/data/samples.js] 3종 골든 샘플 프리셋 및 안전 파서
// ----------------------------------------------------------------------------
export const GOLDEN_SAMPLES = {
  normal: {
    id: "LOT-2026-N01",
    label: "정상 샘플 (Nominal Spec)",
    eqpId: "ETCH-CHAMBER-01",
    ucl: 75.0,
    lcl: 65.0,
    sensorSeries: [69.8, 70.1, 70.4, 69.9, 70.2, 70.0, 69.7, 70.3, 70.1, 69.9],
    stepYields: [
      { step: "Photo", rate: 0.995 },
      { step: "Etch", rate: 0.992 },
      { step: "Deposition", rate: 0.994 },
      { step: "Clean", rate: 0.998 }
    ],
    // 10x10 Wafer Map (0: Pass, 1: Fail)
    waferGrid: Array.from({ length: 100 }, (_, i) => (i === 12 || i === 87 ? 1 : 0))
  },
  warning: {
    id: "LOT-2026-W02",
    label: "경고 샘플 (임계치 근접 & Edge Ring 징후)",
    eqpId: "ETCH-CHAMBER-02",
    ucl: 75.0,
    lcl: 65.0,
    sensorSeries: [70.5, 71.2, 72.0, 72.8, 73.5, 73.9, 74.2, 74.5, 74.7, 74.8],
    stepYields: [
      { step: "Photo", rate: 0.985 },
      { step: "Etch", rate: 0.942 },
      { step: "Deposition", rate: 0.978 },
      { step: "Clean", rate: 0.990 }
    ],
    waferGrid: Array.from({ length: 100 }, (_, i) => {
      const x = i % 10, y = Math.floor(i / 10);
      return (x === 0 || x === 9 || y === 0) && i % 2 === 0 ? 1 : 0;
    })
  },
  violation: {
    id: "LOT-2026-V03",
    label: "위반/불량 샘플 (UCL 초과 & Cluster 불량)",
    eqpId: "ETCH-CHAMBER-03",
    ucl: 75.0,
    lcl: 65.0,
    sensorSeries: [71.0, 73.4, null, 75.8, 77.2, 78.5, 79.1, 77.9, 76.4, 78.0],
    stepYields: [
      { step: "Photo", rate: 0.970 },
      { step: "Etch", rate: 0.765 },
      { step: "Deposition", rate: 0.940 },
      { step: "Clean", rate: 0.960 }
    ],
    waferGrid: Array.from({ length: 100 }, (_, i) => {
      const x = i % 10, y = Math.floor(i / 10);
      return (x >= 3 && x <= 7 && y >= 3 && y <= 7) ? 1 : 0;
    })
  }
};

export function sanitizeAndParseInput(raw) {
  if (!raw || typeof raw !== "object") {
    return { valid: false, error: "입력 데이터가 비어있거나 객체 형식이 아닙니다.", data: GOLDEN_SAMPLES.normal };
  }
  const ucl = Number(raw.ucl) || 75.0;
  const lcl = Number(raw.lcl) || 65.0;
  const rawSeries = Array.isArray(raw.sensorSeries) ? raw.sensorSeries : [];
  const validSeries = [];
  let missingCount = 0;

  rawSeries.forEach((v) => {
    const num = Number(v);
    if (v === null || v === undefined || v === "" || Number.isNaN(num)) {
      missingCount++;
    } else {
      validSeries.push(num);
    }
  });

  const stepYields = Array.isArray(raw.stepYields)
    ? raw.stepYields.map((s) => ({
        step: String(s?.step || "Unknown"),
        rate: Math.min(1, Math.max(0, Number(s?.rate) || 0))
      }))
    : [];

  const waferGrid = Array.isArray(raw.waferGrid) && raw.waferGrid.length === 100
    ? raw.waferGrid.map((d) => (Number(d) === 1 ? 1 : 0))
    : Array(100).fill(0);

  return {
    valid: validSeries.length > 0,
    missingCount,
    data: {
      id: String(raw.id || "LOT-UNKNOWN"),
      eqpId: String(raw.eqpId || "EQP-00"),
      ucl,
      lcl,
      sensorSeries: validSeries,
      stepYields,
      waferGrid
    }
  };
}

// ----------------------------------------------------------------------------
// 2. [src/core/rules.js] 100% 결정론 코어 (80% 룰 로직: 통계, FDC, 수율, 웨이퍼 패턴)
// ----------------------------------------------------------------------------
export function evaluateCoreRules(rawInput) {
  const parsed = sanitizeAndParseInput(rawInput);
  if (!parsed.valid) {
    return {
      status: "VIOLATION",
      score: 0,
      safeHandled: true,
      reason: parsed.error || "유효한 센서 시계열 데이터가 없습니다.",
      metrics: { mean: 0, max: 0, min: 0, oocCount: 0, cumulativeYield: 0, waferYield: 0, pattern: "INVALID_INPUT" }
    };
  }

  const { id, eqpId, ucl, lcl, sensorSeries, stepYields, waferGrid } = parsed.data;

  // (1) FDC 시계열 통계 및 UCL/LCL 판정
  const mean = Number((sensorSeries.reduce((a, b) => a + b, 0) / sensorSeries.length).toFixed(2));
  const max = Math.max(...sensorSeries);
  const min = Math.min(...sensorSeries);
  const marginBand = (ucl - lcl) * 0.15; // 상하한 15% 이내 접근 시 경고

  const oocPoints = sensorSeries.filter((v) => v > ucl || v < lcl);
  const nearLimitPoints = sensorSeries.filter(
    (v) => (v <= ucl && v >= ucl - marginBand) || (v >= lcl && v <= lcl + marginBand)
  );

  // (2) 스텝별 누적 수율(Cumulative Yield) 및 병목 공정(Worst Step) 도출
  const cumulative = stepYields.reduce((acc, cur) => acc * cur.rate, 1);
  const cumulativeYield = Number((cumulative * 100).toFixed(2));
  const worstStepObj = [...stepYields].sort((a, b) => a.rate - b.rate)[0] || { step: "N/A", rate: 1 };

  // (3) 웨이퍼 맵 다이 수율 및 공간 결함 패턴 분류
  let failDies = 0;
  let edgeFails = 0;
  let centerClusterFails = 0;

  waferGrid.forEach((val, idx) => {
    if (val === 1) {
      failDies++;
      const x = idx % 10, y = Math.floor(idx / 10);
      if (x === 0 || x === 9 || y === 0 || y === 9) edgeFails++;
      if (x >= 3 && x <= 7 && y >= 3 && y <= 7) centerClusterFails++;
    }
  });

  const waferYield = Number((((100 - failDies) / 100) * 100).toFixed(1));
  let pattern = "NORMAL_RANDOM";
  if (centerClusterFails >= 12) pattern = "CLUSTER_CRITICAL";
  else if (failDies >= 6 && edgeFails / failDies >= 0.65) pattern = "EDGE_RING_WARN";

  // (4) 종합 상태 및 건강도 점수(0~100) 결정론적 산출
  let status = "NORMAL";
  const violations = [];

  if (oocPoints.length > 0) violations.push(`센서 스펙 이탈(OOC) ${oocPoints.length}회 발생 (최대 ${max})`);
  if (cumulativeYield < 85.0) violations.push(`누적 공정 수율 임계치 미달 (${cumulativeYield}%)`);
  if (pattern === "CLUSTER_CRITICAL") violations.push(`웨이퍼 중심부 군집 불량(${centerClusterFails}개 Die) 감지`);

  if (violations.length > 0) {
    status = "VIOLATION";
  } else if (nearLimitPoints.length >= 2 || cumulativeYield < 93.0 || pattern === "EDGE_RING_WARN" || parsed.missingCount > 0) {
    status = "WARNING";
    if (nearLimitPoints.length >= 2) violations.push(`센서 상하한 경고 구간 진입 (${nearLimitPoints.length}회)`);
    if (pattern === "EDGE_RING_WARN") violations.push(`웨이퍼 가장자리(Edge Ring) 불량 집중 징후`);
    if (parsed.missingCount > 0) violations.push(`센서 결측치(Null) ${parsed.missingCount}건 자동 보정됨`);
  }

  const rawScore = 100 - oocPoints.length * 15 - nearLimitPoints.length * 4 - failDies * 1.2 - parsed.missingCount * 5;
  const score = Math.max(0, Math.min(100, Math.round(rawScore)));

  return {
    status,
    score,
    lotId: id,
    eqpId,
    missingCount: parsed.missingCount,
    violations,
    metrics: {
      mean,
      max,
      min,
      ucl,
      lcl,
      oocCount: oocPoints.length,
      nearCount: nearLimitPoints.length,
      cumulativeYield,
      worstStep: `${worstStepObj.step} (${(worstStepObj.rate * 100).toFixed(1)}%)`,
      waferYield,
      failDies,
      pattern
    },
    series: sensorSeries,
    waferGrid
  };
}

// ----------------------------------------------------------------------------
// 3. [src/ai/reporter.js] AI 요약 해석 (20%) 및 무중단 Fallback 안전장치
// ----------------------------------------------------------------------------
export async function generateInsightWithFallback(coreResult, customApiCall = null) {
  try {
    if (typeof customApiCall === "function") {
      const aiResponse = await Promise.race([
        customApiCall(coreResult),
        new Promise((_, reject) => setTimeout(() => reject(new Error("LLM_TIMEOUT_3000MS")), 3000))
      ]);
      if (aiResponse && typeof aiResponse === "string") {
        return { source: "AI_LIVE", text: aiResponse };
      }
    }
    throw new Error("USE_DETERMINISTIC_FALLBACK");
  } catch (err) {
    const m = coreResult.metrics || {};
    if (coreResult.status === "NORMAL") {
      return {
        source: "FALLBACK_SAFE_GUARD",
        text: `[정상 가동 브리핑] 설비(${coreResult.eqpId}) 평균 측정값은 ${m.mean}(스펙 ${m.lcl}~${m.ucl})으로 안정적입니다. 누적 공정 수율 ${m.cumulativeYield}%, 웨이퍼 양품률 ${m.waferYield}%로 현 공정 레시피 유지를 권고합니다.`
      };
    }
    if (coreResult.status === "WARNING") {
      return {
        source: "FALLBACK_SAFE_GUARD",
        text: `[예방 점검 권고] 설비(${coreResult.eqpId})에서 경계치 근접(${m.nearCount}회) 및 패턴(${m.pattern})이 감지되었습니다. 병목 공정[${m.worstStep}]의 챔버 압력/온도 드리프트를 점검하고 다음 PM 주기에 세정을 앞당기십시오.`
      };
    }
    return {
      source: "FALLBACK_SAFE_GUARD",
      text: `[긴급 Interlock 조치 지시] 설비(${coreResult.eqpId}) 스펙 이탈(${m.oocCount}회, 최고치 ${m.max}) 및 웨이퍼 ${m.pattern} 불량(수율 ${m.waferYield}%)이 확정되었습니다. 즉시 해당 LOT(${coreResult.lotId})을 홀드(HOLD)하고 병목 공정[${m.worstStep}]의 RF/가스 유량계를 긴급 점검하십시오.`
    };
  }
}

// ----------------------------------------------------------------------------
// 4. [src/components/Dashboard.jsx] 프리셋 3종 버튼 + SVG 차트 + 웨이퍼 그리드 UI
// ----------------------------------------------------------------------------
import React, { useState, useEffect } from "react";

export default function MainWorkspaceView() {
  const [activeKey, setActiveKey] = useState("normal");
  const [inputJson, setInputJson] = useState(() => JSON.stringify(GOLDEN_SAMPLES.normal, null, 2));
  const [coreRes, setCoreRes] = useState(() => evaluateCoreRules(GOLDEN_SAMPLES.normal));
  const [aiReport, setAiReport] = useState({ source: "INIT", text: "분석 중..." });

  const runPipeline = async (rawObj) => {
    const evaluated = evaluateCoreRules(rawObj);
    setCoreRes(evaluated);
    const insight = await generateInsightWithFallback(evaluated);
    setAiReport(insight);
  };

  useEffect(() => {
    runPipeline(GOLDEN_SAMPLES.normal);
  }, []);

  const handlePresetClick = (key) => {
    setActiveKey(key);
    const sample = GOLDEN_SAMPLES[key];
    setInputJson(JSON.stringify(sample, null, 2));
    runPipeline(sample);
  };

  const handleManualExecute = () => {
    try {
      const parsed = JSON.parse(inputJson);
      runPipeline(parsed);
    } catch (e) {
      runPipeline(null);
    }
  };

  const badgeColor =
    coreRes.status === "NORMAL"
      ? "#16a34a"
      : coreRes.status === "WARNING"
      ? "#d97706"
      : "#dc2626";

  return (
    <div style={{ fontFamily: "sans-serif", maxWidth: 1200, margin: "0 auto", padding: 20, backgroundColor: "#f8fafc", minHeight: "100vh" }}>
      {/* 헤더 및 3종 골든 샘플 원클릭 바 */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", background: "#0f172a", color: "#fff", padding: "16px 24px", borderRadius: 10, marginBottom: 20 }}>
        <div>
          <h1 style={{ margin: 0, fontSize: 20 }}>⚙️ FDE 반도체 FDC 센서 & 웨이퍼 수율 통합 판정 시스템</h1>
          <p style={{ margin: "4px 0 0", fontSize: 13, color: "#94a3b8" }}>결정론 코어(80% 수식/3σ 판정) + AI 요약 및 무중단 Fallback(20%) 아키텍처</p>
        </div>
        <div style={{ display: "flex", gap: 10 }}>
          <button onClick={() => handlePresetClick("normal")} style={{ padding: "8px 14px", borderRadius: 6, border: "none", cursor: "pointer", fontWeight: "bold", background: activeKey === "normal" ? "#22c55e" : "#334155", color: "#fff" }}>
            🟢 [정상 샘플 입력]
          </button>
          <button onClick={() => handlePresetClick("warning")} style={{ padding: "8px 14px", borderRadius: 6, border: "none", cursor: "pointer", fontWeight: "bold", background: activeKey === "warning" ? "#f59e0b" : "#334155", color: "#fff" }}>
            🟡 [경고(임계치) 샘플 입력]
          </button>
          <button onClick={() => handlePresetClick("violation")} style={{ padding: "8px 14px", borderRadius: 6, border: "none", cursor: "pointer", fontWeight: "bold", background: activeKey === "violation" ? "#ef4444" : "#334155", color: "#fff" }}>
            🔴 [위반/불량 샘플 입력]
          </button>
        </div>
      </div>

      {/* 상단 핵심 KPI 카드 4개 */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 14, marginBottom: 20 }}>
        <div style={{ background: "#fff", padding: 16, borderRadius: 8, borderLeft: `6px solid ${badgeColor}`, boxShadow: "0 1px 3px rgba(0,0,0,0.08)" }}>
          <div style={{ fontSize: 12, color: "#64748b" }}>종합 판정 상태 (Status)</div>
          <div style={{ fontSize: 24, fontWeight: "bold", color: badgeColor, marginTop: 4 }}>{coreRes.status} ({coreRes.score}점)</div>
        </div>
        <div style={{ background: "#fff", padding: 16, borderRadius: 8, boxShadow: "0 1px 3px rgba(0,0,0,0.08)" }}>
          <div style={{ fontSize: 12, color: "#64748b" }}>FDC 센서 평균 / OOC 횟수</div>
          <div style={{ fontSize: 22, fontWeight: "bold", marginTop: 4 }}>{coreRes.metrics?.mean} / 이탈 {coreRes.metrics?.oocCount}건</div>
        </div>
        <div style={{ background: "#fff", padding: 16, borderRadius: 8, boxShadow: "0 1px 3px rgba(0,0,0,0.08)" }}>
          <div style={{ fontSize: 12, color: "#64748b" }}>누적 공정 수율 (병목 공정)</div>
          <div style={{ fontSize: 20, fontWeight: "bold", marginTop: 4 }}>{coreRes.metrics?.cumulativeYield}% <span style={{ fontSize: 13, color: "#dc2626" }}>({coreRes.metrics?.worstStep})</span></div>
        </div>
        <div style={{ background: "#fff", padding: 16, borderRadius: 8, boxShadow: "0 1px 3px rgba(0,0,0,0.08)" }}>
          <div style={{ fontSize: 12, color: "#64748b" }}>웨이퍼 수율 & 결함 패턴</div>
          <div style={{ fontSize: 20, fontWeight: "bold", marginTop: 4 }}>{coreRes.metrics?.waferYield}% ({coreRes.metrics?.pattern})</div>
        </div>
      </div>

      {/* 중앙 차트 & 웨이퍼 맵 그리드 */}
      <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: 20, marginBottom: 20 }}>
        {/* FDC 시계열 SVG 차트 */}
        <div style={{ background: "#fff", padding: 20, borderRadius: 8, boxShadow: "0 1px 3px rgba(0,0,0,0.08)" }}>
          <h3 style={{ marginTop: 0, fontSize: 16 }}>📈 FDC 센서 시계열 추이 및 3-Sigma UCL/LCL 임계선</h3>
          <svg width="100%" height="220" viewBox="0 0 600 220" style={{ background: "#f8fafc", borderRadius: 6, border: "1px solid #e2e8f0" }}>
            {/* UCL (75) & LCL (65) 기준선 */}
            <line x1="40" y1="40" x2="580" y2="40" stroke="#ef4444" strokeDasharray="5,5" strokeWidth="2" />
            <text x="45" y="34" fill="#ef4444" fontSize="11" fontWeight="bold">UCL ({coreRes.metrics?.ucl})</text>
            <line x1="40" y1="180" x2="580" y2="180" stroke="#3b82f6" strokeDasharray="5,5" strokeWidth="2" />
            <text x="45" y="196" fill="#3b82f6" fontSize="11" fontWeight="bold">LCL ({coreRes.metrics?.lcl})</text>

            {/* 데이터 포인트 플롯 */}
            {(coreRes.series || []).map((val, idx, arr) => {
              const x = 60 + (idx * 500) / Math.max(1, arr.length - 1);
              const clamped = Math.max(60, Math.min(80, val));
              const y = 180 - ((clamped - 65) / 10) * 140;
              const isOut = val > (coreRes.metrics?.ucl || 75) || val < (coreRes.metrics?.lcl || 65);
              return (
                <g key={idx}>
                  <circle cx={x} cy={y} r={isOut ? 6 : 4} fill={isOut ? "#dc2626" : "#0f172a"} />
                  <text x={x - 10} y={y - 10} fontSize="10" fill={isOut ? "#dc2626" : "#475569"}>{val}</text>
                </g>
              );
            })}
          </svg>
        </div>

        {/* 10x10 웨이퍼 맵 뷰어 */}
        <div style={{ background: "#fff", padding: 20, borderRadius: 8, boxShadow: "0 1px 3px rgba(0,0,0,0.08)", textAlign: "center" }}>
          <h3 style={{ marginTop: 0, fontSize: 16 }}>🔘 Wafer Map (10x10 Die Grid)</h3>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(10, 1fr)", gap: 3, width: 200, margin: "0 auto" }}>
            {(coreRes.waferGrid || []).map((fail, i) => (
              <div
                key={i}
                title={`Die (${i % 10}, ${Math.floor(i / 10)}): ${fail ? "FAIL" : "PASS"}`}
                style={{
                  width: 17,
                  height: 17,
                  borderRadius: 3,
                  backgroundColor: fail ? "#ef4444" : "#22c55e"
                }}
              />
            ))}
          </div>
          <div style={{ fontSize: 12, color: "#64748b", marginTop: 10 }}>
            초록: 양품(Pass) / 빨강: 불량(Fail {coreRes.metrics?.failDies}개)
          </div>
        </div>
      </div>

      {/* 하단: 결정론 위반 내역 + AI/Fallback 리포트 + 데이터 에디터 */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        <div style={{ background: "#fff", padding: 20, borderRadius: 8, boxShadow: "0 1px 3px rgba(0,0,0,0.08)" }}>
          <h3 style={{ marginTop: 0, fontSize: 16 }}>🤖 AI 조치 브리핑 & 결정론적 위반 근거 (Source: {aiReport.source})</h3>
          <div style={{ padding: 14, background: "#f1f5f9", borderRadius: 6, lineHeight: 1.6, fontSize: 14, marginBottom: 14 }}>
            {aiReport.text}
          </div>
          <h4 style={{ fontSize: 14, marginBottom: 8 }}>📌 결정론 코어(rules.js) 감지 내역:</h4>
          {coreRes.violations?.length === 0 ? (
            <div style={{ color: "#16a34a", fontSize: 13 }}>✅ 모든 파라미터가 정상 스펙 내에 있습니다.</div>
          ) : (
            <ul style={{ margin: 0, paddingLeft: 20, color: "#b91c1c", fontSize: 13 }}>
              {coreRes.violations?.map((v, i) => <li key={i}>{v}</li>)}
            </ul>
          )}
        </div>

        <div style={{ background: "#fff", padding: 20, borderRadius: 8, boxShadow: "0 1px 3px rgba(0,0,0,0.08)" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
            <h3 style={{ margin: 0, fontSize: 16 }}>🧾 원본 입력 데이터 (JSON 직접 수정 테스트 가능)</h3>
            <button onClick={handleManualExecute} style={{ padding: "6px 12px", background: "#2563eb", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer", fontWeight: "bold" }}>
              ▶ 분석 실행
            </button>
          </div>
          <textarea
            value={inputJson}
            onChange={(e) => setInputJson(e.target.value)}
            rows={8}
            style={{ width: "100%", fontFamily: "monospace", fontSize: 12, padding: 8, borderRadius: 6, border: "1px solid #cbd5e1" }}
          />
        </div>
      </div>
    </div>
  );
}
