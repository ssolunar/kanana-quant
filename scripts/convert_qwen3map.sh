#!/usr/bin/env bash
# Kanana2Tiny -> Qwen3 아키텍처 매핑 변환 + Q4_K_M 양자화
# 배경: llama.cpp convert_hf_to_gguf.py가 Kanana2TinyForCausalLM을 지원하지 않아,
#       config.json의 아키텍처를 Qwen3ForCausalLM으로 매핑하여 변환한다.
#       SWA(window 1024) 레이어 배치와 YaRN rope가 제거되므로 컨텍스트 4096 이하 사용 권장.
# 사전 조건: scripts/quantize.sh 의 [1/6]~[3/6] 단계 완료 (venv, llama.cpp 빌드, 모델 다운로드)
set -euo pipefail
WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$WORK_DIR"
source .venv/bin/activate

SRC=kanana-2-1.3b-instruct
DST=kanana-2-1.3b-qwen3map

echo "=== [1/5] 파일 복사 (가중치+토크나이저만) ==="
rm -rf "$DST" && mkdir -p "$DST"
cp "$SRC"/*.safetensors "$SRC"/*.json "$DST"/
cp "$SRC"/tokenizer* "$DST"/ 2>/dev/null || true
cp "$SRC"/*.jinja "$DST"/ 2>/dev/null || true
rm -f "$DST"/*.py 2>/dev/null || true

echo "=== [2/5] config.json 패치: Kanana2Tiny -> Qwen3 ==="
python3 << 'PYEOF'
import json
p = 'kanana-2-1.3b-qwen3map/config.json'
c = json.load(open(p))
c['architectures'] = ['Qwen3ForCausalLM']
c['model_type'] = 'qwen3'
for k in ['auto_map','layer_types','sliding_window','use_sliding_window',
          'max_window_layers','rope_parameters']:
    c.pop(k, None)
c['rope_scaling'] = None
json.dump(c, open(p, 'w'), indent=2)
print('patched:', c['architectures'], c['model_type'])
PYEOF

echo "=== [3/5] GGUF(f16) 변환 ==="
python llama.cpp/convert_hf_to_gguf.py "$DST" \
    --outfile kanana-2-1.3b-instruct-f16.gguf --outtype f16

echo "=== [4/5] Q4_K_M 양자화 ==="
./llama.cpp/build/bin/llama-quantize \
    kanana-2-1.3b-instruct-f16.gguf Kanana-2-1.3b-instruct-Q4_K_M.gguf Q4_K_M

echo "=== [5/5] 스모크 테스트 ==="
./llama.cpp/build/bin/llama-cli -m Kanana-2-1.3b-instruct-Q4_K_M.gguf \
    -p "안녕하세요, 자기소개 해주세요." -n 128 --temp 0.7 -c 4096

ls -lh "$WORK_DIR"/*.gguf
