#!/usr/bin/env bash
set -euo pipefail

echo "================================================================"
echo "🚨 [Final Gatekeeper] 제출 5분 전 실격/감점 요인 최종 정밀 감사"
echo "================================================================"

FAIL_FLAG=0

# 1. 임시 감사 파일 및 외부 툴킷 폴더 잔존 여부 확인
for leftover in ".fde_data_profile.md" ".fde_audit_report.md" "fde-autopilot" "fde-kit"; do
  if [ -e "$leftover" ]; then
    echo "⚠️ [주의] 작업 폴더 내에 참조용 파일/폴더($leftover)가 남아 있습니다!"
    echo "   ↳ 제출물에 섞이지 않도록 삭제 명령어 실행 권장: rm -rf $leftover"
    FAIL_FLAG=$((FAIL_FLAG+1))
  fi
done

# 2. 필수 문서 3종 확인
for doc in SPEC.md CLAUDE.md HANDOFF.md; do
  if [ ! -f "$doc" ]; then
    echo "❌ [치명적 누락] $doc 파일이 없습니다!"
    FAIL_FLAG=$((FAIL_FLAG+1))
  else
    echo "✅ [필수 문서] $doc 확인 완료"
  fi
done

# 3. 서버 프로세스 생존 여부 확인 (제출 및 채점 중 서버가 켜져 있어야 함)
if ps aux | grep -E "vite|next|node|uvicorn|flask|python" | grep -v grep | grep -v "final_gatekeeper" > /dev/null; then
  echo "✅ [서버 생존] 애플리케이션 웹 서버가 정상 실행 중입니다. (절대 끄지 마세요!)"
else
  echo "❌ [치명적 경고] 현재 실행 중인 웹 서버 프로세스가 감지되지 않습니다!"
  echo "   ↳ 터미널 1번에서 반드시 서버(--host 0.0.0.0)를 켜둔 상태로 제출하세요!"
  FAIL_FLAG=$((FAIL_FLAG+1))
fi

# 4. Git 워킹 트리 클린 상태 및 STATE 커밋 이력 점검
if [ -d ".git" ]; then
  UNCOMMITTED=$(git status --porcelain | wc -l)
  if [ "$UNCOMMITTED" -gt 0 ]; then
    echo "⚠️ [미커밋 파일] 아직 커밋되지 않은 변경사항이 ${UNCOMMITTED}건 있습니다. 최종 git commit을 수행하세요."
  else
    echo "✅ [Git 클린] 모든 변경사항이 커밋되었습니다."
  fi
  echo "📜 [최근 커밋 히스토리 (상위 7개)]:"
  git log --oneline -n 7
fi

echo "================================================================"
if [ "$FAIL_FLAG" -eq 0 ]; then
  echo "🏆 완벽합니다! HANDOFF.md의 핵심 함수명 2개만 기억하고 [제출하고 문제풀기]를 누르세요!"
else
  echo "⚠️ 위 경고 항목(${FAIL_FLAG}건)을 조치한 뒤 제출하세요!"
fi
echo "================================================================"