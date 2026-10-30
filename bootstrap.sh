#!/usr/bin/env bash
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$(pwd)}"

echo "================================================================"
echo "🛡️ [FDE-Autopilot] 안전 부트스트랩 및 워크스페이스 초기화"
echo "================================================================"

# 1. 클론된 킷 자체의 git remote 제거 (실수로 git push 하여 실격되는 현상 100% 방지)
if [ -d "${KIT_DIR}/.git" ]; then
    rm -rf "${KIT_DIR}/.git"
    echo "✅ [보안 완료] 툴킷 내부 .git 메타데이터 파기 완료 (외부 Push 원천 차단)"
fi

# 2. 대상 작업 폴더의 git remote 점검 및 차단
if [ -d "${TARGET_DIR}/.git" ]; then
    cd "${TARGET_DIR}"
    if git remote | grep -q .; then
        for r in $(git remote); do
            git remote remove "$r"
            echo "✅ [보안 완료] 작업 폴더 원격 저장소($r) 연결 해제 완료"
        done
    fi
fi

# 3. 대상 작업 폴더의 .gitignore에 툴킷 폴더 등록 (제출물에 툴킷 파일이 섞여 들어가는 것 방지)
GITIGNORE_FILE="${TARGET_DIR}/.gitignore"
KIT_FOLDER_NAME="$(basename "${KIT_DIR}")"
if [ "${KIT_DIR}" != "${TARGET_DIR}" ]; then
    if ! grep -qxF "${KIT_FOLDER_NAME}/" "${GITIGNORE_FILE}" 2>/dev/null; then
        echo "" >> "${GITIGNORE_FILE}"
        echo "# FDE Local Reference Toolkit (Excluded from submission)" >> "${GITIGNORE_FILE}"
        echo "${KIT_FOLDER_NAME}/" >> "${GITIGNORE_FILE}"
        echo ".fde_audit_cache/" >> "${GITIGNORE_FILE}"
        echo "✅ [흔적 관리] .gitignore에 ${KIT_FOLDER_NAME}/ 제외 설정 완료"
    fi
fi

# 4. 엔진 실행 권한 부여
chmod +x "${KIT_DIR}/engine/"*.sh 2>/dev/null || true

# 5. 작업 폴더 내 데이터 및 요구사항 자동 프로파일링 실행
echo "🔍 [데이터 스캔] 현재 과제의 데이터셋 및 명세서 자동 해부 중..."
python3 "${KIT_DIR}/engine/workspace_profiler.py" --root "${TARGET_DIR}" --out "${TARGET_DIR}/.fde_data_profile.md"

echo "================================================================"
echo "🎯 준비 완료! 생성된 '.fde_data_profile.md'를 확인하고 Step 1을 시작하세요."
echo "================================================================"
