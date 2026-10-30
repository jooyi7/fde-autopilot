#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="${1:-$(pwd)}"

echo "🚀 [FDE Autopilot] Final Gatekeeper 가동 중..."
python3 "${SCRIPT_DIR}/final_gatekeeper.py" "${WORKSPACE_ROOT}"
