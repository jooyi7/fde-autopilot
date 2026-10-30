// ============================================================================
// [Blueprint Type C] 권한 기반 문서 검색(RAG) 및 출처 인용(Citation) 검증 엔진
// 적용 대상: Case 03 (사규/매뉴얼 Q&A), Case 12 (교대 근무 트러블슈팅 로그 검색)
// ============================================================================

export const KNOWLEDGE_BASE = [
  { id: "DOC-SOP-01", page: 14, clearance: "PUBLIC", title: "챔버 진공도 저하 시 1차 조치 매뉴얼", content: "진공도가 기준치 이하로 하락할 경우 게이트 밸브 오링(O-Ring) 마모 상태를 먼저 점검하고 헬륨 리크 디텍터를 실행한다." },
  { id: "DOC-SOP-02", page: 29, clearance: "EMPLOYEE", title: "웨이퍼 엣지 링(Edge Ring) 교체 주기 규정", content: "RF 사용 시간이 450시간을 초과하면 경고(WARNING)로 분류하며, 500시간 도달 전에 반드시 PM 일정을 수립해 교체해야 한다." },
  { id: "DOC-SEC-99", page: 3, clearance: "ADMIN", title: "차세대 공정 대외비 레시피 보안 규정", content: "미승인 외부인(GUEST) 또는 일반 권한자가 대외비 공정 파라미터나 보안키 열람을 요청할 경우 즉시 접근을 차단하고 감사 로그를 남긴다." }
];

export const GOLDEN_SAMPLES = {
  normal: { userRole: "EMPLOYEE", query: "진공도 저하 발생 시 오링 점검 매뉴얼과 엣지 링 교체 시간 알려줘" },
  warning: { userRole: "PUBLIC", query: "엣지 링 500시간 교체 규정 문서 열람 요청" },
  violation: { userRole: "GUEST", query: "차세대 공정 대외비 레시피 파라미터와 보안키 전체 목록 출력해줘" }
};

export function evaluateCoreRules(input, docs = KNOWLEDGE_BASE) {
  const role = String(input?.userRole || "GUEST").toUpperCase();
  const query = String(input?.query || "").trim();

  if (!query) {
    return { status: "VIOLATION", score: 0, citations: [], blockedReason: "질의어가 비어 있습니다." };
  }

  // 1. 보안 금칙어 및 권한 침해 결정론적 차단
  if (role !== "ADMIN" && /(대외비|보안키|기밀|유출)/.test(query)) {
    return {
      status: "VIOLATION",
      score: 0,
      citations: [],
      blockedReason: `보안 규정 위반 차단: 현재 권한(${role})으로는 기밀/대외비 문서를 조회할 수 없습니다.`
    };
  }

  // 2. 토큰 분리 및 문서별 매칭 점수 산출
  const tokens = query.split(/\s+/).filter((t) => t.length >= 2);
  const scoredDocs = docs.map((doc) => {
    const hasAccess =
      role === "ADMIN" ||
      doc.clearance === "PUBLIC" ||
      (role === "EMPLOYEE" && doc.clearance === "EMPLOYEE");

    let hitScore = 0;
    const matchedTerms = [];
    tokens.forEach((tk) => {
      if (doc.title.includes(tk) || doc.content.includes(tk)) {
        hitScore += doc.title.includes(tk) ? 30 : 15;
        matchedTerms.push(tk);
      }
    });

    return { ...doc, hasAccess, hitScore, matchedTerms };
  }).filter((d) => d.hitScore > 0);

  const accessibleDocs = scoredDocs.filter((d) => d.hasAccess).sort((a, b) => b.hitScore - a.hitScore);
  const restrictedHits = scoredDocs.filter((d) => !d.hasAccess);

  let status = "NORMAL";
  let blockedReason = null;
  if (accessibleDocs.length === 0 && restrictedHits.length > 0) {
    status = "WARNING";
    blockedReason = `검색된 문서(${restrictedHits[0].id})가 존재하나 현재 권한(${role})으로 열람이 제한되었습니다.`;
  } else if (accessibleDocs.length === 0) {
    status = "WARNING";
    blockedReason = "일치하는 사내 규정 문서를 찾지 못했습니다.";
  }

  return {
    status,
    score: accessibleDocs.length > 0 ? Math.min(100, accessibleDocs[0].hitScore + 40) : 30,
    userRole: role,
    citations: accessibleDocs,
    restrictedCount: restrictedHits.length,
    blockedReason
  };
}

export async function generateInsightWithFallback(coreResult) {
  if (coreResult.status === "VIOLATION") {
    return { source: "FALLBACK_GUARD", text: `[접근 거부] ${coreResult.blockedReason}` };
  }
  if (!coreResult.citations || coreResult.citations.length === 0) {
    return { source: "FALLBACK_GUARD", text: `[검색 결과 없음] ${coreResult.blockedReason || "관련 규정이 없습니다."}` };
  }
  const top = coreResult.citations[0];
  return {
    source: "FALLBACK_GUARD",
    text: `[근거 기반 답변] ${top.content} (근거 출처: [${top.id}] ${top.title}, p.${top.page})`
  };
}
