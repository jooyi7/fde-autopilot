#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "===================================================="
echo "🔍 [Auditor Worker] Running Automated Quality Audit"
echo "===================================================="

# 1. 결정론 코어 하네스 실행
if [ -f "$SCRIPT_DIR/verify_core.mjs" ]; then
    echo "-> [Step 1] Running verify_core.mjs..."
    node "$SCRIPT_DIR/verify_core.mjs"
elif [ -f "$SCRIPT_DIR/deterministic_harness.mjs" ]; then
    echo "-> [Step 1] Running deterministic_harness.mjs..."
    node "$SCRIPT_DIR/deterministic_harness.mjs"
fi

# 2. 릴리즈 게이트키퍼 (localhost 하드코딩, 빈 문서, 시크릿 노출 검사)
if [ -f "$SCRIPT_DIR/release_gate.py" ]; then
    echo "-> [Step 2] Running release_gate.py..."
    python3 "$SCRIPT_DIR/release_gate.py" "$WORKSPACE_ROOT"
elif [ -f "$SCRIPT_DIR/final_gatekeeper.py" ]; then
    echo "-> [Step 2] Running final_gatekeeper.py..."
    python3 "$SCRIPT_DIR/final_gatekeeper.py" "$WORKSPACE_ROOT"
fi

echo "===================================================="
echo "✅ Audit Complete."
echo "===================================================="