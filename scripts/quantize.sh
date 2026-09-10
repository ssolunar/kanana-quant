#!/usr/bin/env bash
# Kanana-2-1.3B-Instruct → GGUF Q4_K_M 양자화 파이프라인
# 사용법: bash scripts/quantize.sh   (SSAFY GPU 서버, ~/kanana-quant 에서 실행)
set -euo pipefail

WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$WORK_DIR"

MODEL_ID="kakaocorp/kanana-2-1.3b-instruct"
MODEL_DIR="$WORK_DIR/kanana-2-1.3b-instruct"
F16_GGUF="$WORK_DIR/kanana-2-1.3b-instruct-f16.gguf"
Q4_GGUF="$WORK_DIR/Kanana-2-1.3b-instruct-Q4_K_M.gguf"   # 'Kanana-' 접두어: 라이선스 §3.1(v)

echo "=== [1/6] Python venv + 패키지 ==="
if [ ! -d .venv ]; then python3 -m venv .venv; fi
source .venv/bin/activate
pip install -q -U pip "transformers>=4.57" torch huggingface_hub sentencepiece

echo "=== [2/6] llama.cpp 클론 + 빌드 (CPU) ==="
if [ ! -d llama.cpp ]; then
    git clone --depth 1 https://github.com/ggml-org/llama.cpp
fi
cmake -S llama.cpp -B llama.cpp/build -DCMAKE_BUILD_TYPE=Release
cmake --build llama.cpp/build -j 48
pip install -q -r llama.cpp/requirements/requirements-convert_hf_to_gguf.txt

echo "=== [3/6] 모델 다운로드 (~3GB) ==="
if [ ! -f "$MODEL_DIR/config.json" ]; then
    hf download "$MODEL_ID" --local-dir "$MODEL_DIR"
fi

echo "=== [4/6] HF → GGUF(f16) 변환 — Kanana2Tiny 아키텍처 지원 여부 판가름 지점 ==="
python llama.cpp/convert_hf_to_gguf.py "$MODEL_DIR" --outfile "$F16_GGUF" --outtype f16

echo "=== [5/6] Q4_K_M 양자화 ==="
./llama.cpp/build/bin/llama-quantize "$F16_GGUF" "$Q4_GGUF" Q4_K_M

echo "=== [6/6] 스모크 테스트 ==="
./llama.cpp/build/bin/llama-cli -m "$Q4_GGUF" -p "안녕하세요, 자기소개 해주세요." -n 128 --temp 0.7

echo ""
echo "완료. 산출물:"
ls -lh "$F16_GGUF" "$Q4_GGUF"
echo "예상 크기: f16 ~2.6GB / Q4_K_M ~0.85GB"
