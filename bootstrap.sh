#!/usr/bin/env bash
set -e

echo "===================================================="
echo "🚀 Initializing FDE Codex Workspace..."
echo "===================================================="

# 1. 런타임 및 기본 도구 버전 체크
echo "[1/4] Checking Environment Versions..."
node -v 2>/dev/null || echo "Node.js not found"
python3 --version 2>/dev/null || echo "Python3 not found"

# 2. AGENTS.md를 프로젝트 루트에 배치 (이미 없을 경우에만)
if [ ! -f "../AGENTS.md" ] && [ -f "./AGENTS.md" ]; then
    cp ./AGENTS.md ../AGENTS.md
    echo "[2/4] Copied AGENTS.md to workspace root."
else
    echo "[2/4] AGENTS.md ready."
fi

# 3. 초기 워크스페이스 데이터/구조 정밀 스캔 실행
echo "[3/4] Running Workspace Inspector..."
python3 "$(dirname "$0")/engine/workspace_inspector.py" .. > ../WORKSPACE_PROFILE.md
echo " -> Saved profile to ../WORKSPACE_PROFILE.md"

# 4. 제출용 아키텍처 문서 초안 복사 (덮어쓰기 방지)
if [ ! -f "../SOLUTION_NOTES.md" ] && [ -f "./docs_kit/ARCHITECTURE_DECISIONS.md" ]; then
    cp ./docs_kit/ARCHITECTURE_DECISIONS.md ../SOLUTION_NOTES.md
    echo "[4/4] Created ../SOLUTION_NOTES.md template."
fi

echo "===================================================="
echo "✅ Ready! Check WORKSPACE_PROFILE.md and run 'codex'"
echo "===================================================="