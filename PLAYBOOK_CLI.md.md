# ⏱️ FDE 180분 실전 터미널 오퍼레이션 치트시트

> **핵심 수칙**: 클론은 `/tmp/fde-autopilot`에 받거나, 작업 폴더 내에 받았다면 `.gitignore`에 등록 후 제출 직전 삭제(`rm -rf fde-autopilot`)한다.

## 0단계: 시작 후 2분 (환경 세팅 & 데이터 자동 스캔)
```bash
# 터미널 1번에서 실행 (/tmp에 클론하여 작업 공간 오염 원천 방지)
git clone [https://github.com/](https://github.com/)<내아이디>/fde-autopilot.git /tmp/fde-kit
bash /tmp/fde-kit/bootstrap.sh "$(pwd)"

# 스캔된 데이터 요약본 확인
cat .fde_data_profile.md