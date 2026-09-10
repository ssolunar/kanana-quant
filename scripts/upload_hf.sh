#!/usr/bin/env bash
# 양자화 모델 + 라이선스 문서 Hugging Face 업로드
# 사용법: bash scripts/upload_hf.sh <hf-username>
# 사전 조건: hf auth login (write 토큰), quantize.sh 완료
set -euo pipefail

HF_USER="${1:?사용법: bash scripts/upload_hf.sh <hf-username>}"
REPO="$HF_USER/Kanana-2-1.3b-instruct-Q4_K_M-GGUF"   # 'Kanana-' 접두어: 라이선스 §3.1(v)

WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$WORK_DIR"
source .venv/bin/activate 2>/dev/null || true

Q4_GGUF="Kanana-2-1.3b-instruct-Q4_K_M.gguf"
[ -f "$Q4_GGUF" ] || { echo "에러: $Q4_GGUF 없음. scripts/quantize.sh 먼저 실행."; exit 1; }

# 업로드 스테이징: 모델 + 라이선스 문서
STAGE="$WORK_DIR/hf-upload"
mkdir -p "$STAGE"
cp "$Q4_GGUF" "$STAGE/"
cp release/LICENSE release/NOTICE "$STAGE/"
cp release/MODEL_CARD.md "$STAGE/README.md"

hf repo create "$REPO" --repo-type model 2>/dev/null || true
hf upload "$REPO" "$STAGE" . --repo-type model

echo ""
echo "업로드 완료: https://huggingface.co/$REPO"
echo "확인 사항: 모델 카드에 'Powered by Kanana' 표시, LICENSE/NOTICE 동봉 여부"
