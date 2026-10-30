#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${1:-$(pwd)}"
AUDIT_REPORT="${WORKSPACE}/.fde_audit_report.md"

echo "================================================================"
echo "🕵️‍♂️ [Auditor Worker] 독립 감사관 소스코드-문서 교차 검증 시작"
echo "================================================================"

{
  echo "# 🔍 독립 감사관(Auditor) 자동 교차 검증 리포트"
  echo "- 검사 시각: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  echo "## 1. 필수 제출 문서 3종 및 증거 좌표 점검"
} > "${AUDIT_REPORT}"

for doc in SPEC.md CLAUDE.md HANDOFF.md; do
  if [ -f "${WORKSPACE}/${doc}" ]; then
    LINES=$(wc -l < "${WORKSPACE}/${doc}")
    echo "- ✅ \`${doc}\` 존재함 (${LINES} lines)" | tee -a "${AUDIT_REPORT}"
  else
    echo "- ❌ \`${doc}\` **누락됨 (즉시 생성 필요!)**" | tee -a "${AUDIT_REPORT}"
  fi
done

if [ -f "${WORKSPACE}/SPEC.md" ]; then
  COORD_CNT=$(grep -c "구현 좌표" "${WORKSPACE}/SPEC.md" || true)
  echo "- 📌 \`SPEC.md\` 내 '[구현 좌표]' 매핑 개수: **${COORD_CNT}개**" | tee -a "${AUDIT_REPORT}"
  if [ "${COORD_CNT}" -eq 0 ]; then
    echo "  - ⚠️ **경고**: SPEC.md에 실제 파일명과 함수명을 매핑한 '[구현 좌표: src/... - fn()]'가 없습니다!" | tee -a "${AUDIT_REPORT}"
  fi
fi

echo "" >> "${AUDIT_REPORT}"
echo "## 2. 4대 아키텍처 레이어 및 방어 코딩 점검" >> "${AUDIT_REPORT}"

for layer in "src/data" "src/core" "src/ai" "src/components"; do
  if [ -d "${WORKSPACE}/${layer}" ]; then
    FILE_CNT=$(find "${WORKSPACE}/${layer}" -type f | wc -l)
    echo "- ✅ \`${layer}/\` 레이어 분리 확인 (파일 ${FILE_CNT}개)" | tee -a "${AUDIT_REPORT}"
  else
    echo "- ⚠️ \`${layer}/\` 폴더가 보이지 않습니다. 현재 구조 확인 필요." | tee -a "${AUDIT_REPORT}"
  fi
done

# try-catch Fallback 및 0.0.0.0 바인딩 검사
TRY_CNT=$(grep -rn "catch" "${WORKSPACE}/src" 2>/dev/null | wc -l || true)
HOST_BIND=$(grep -rn "0\.0\.0\.0" "${WORKSPACE}" --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=fde-autopilot 2>/dev/null | wc -l || true)

echo "- 🛡️ \`src/\` 내 예외 방어(\`catch\`) 블록 수: **${TRY_CNT}개**" | tee -a "${AUDIT_REPORT}"
echo "- 🌐 \`0.0.0.0\` 호스트 바인딩 설정 감지 수: **${HOST_BIND}건**" | tee -a "${AUDIT_REPORT}"

echo "================================================================"
echo "✅ 감사 리포트 생성 완료: ${AUDIT_REPORT}"
echo "👉 이제 터미널 2번에서 'codex'를 실행하고 Step 4-B 프롬프트를 넣으세요."
echo "================================================================"