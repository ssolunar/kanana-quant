# Kanana-2-1.3B-Instruct 4bit 양자화 (GGUF Q4_K_M)

[kakaocorp/kanana-2-1.3b-instruct](https://huggingface.co/kakaocorp/kanana-2-1.3b-instruct)를
온디바이스(모바일) 추론용 **Q4_K_M GGUF**로 양자화하는 파이프라인.

**Powered by Kanana**

📦 양자화 모델: [ssolunar/Kanana-2-1.3b-instruct-Q4_K_M-GGUF](https://huggingface.co/ssolunar/Kanana-2-1.3b-instruct-Q4_K_M-GGUF)

## 변환 방법 요약

- llama.cpp의 `convert_hf_to_gguf.py`는 이 모델의 커스텀 아키텍처(`Kanana2TinyForCausalLM`)를 지원하지 않음.
- 모델 구조가 Qwen3와 호환되는 점을 이용, config.json의 아키텍처를 `Qwen3ForCausalLM`으로 매핑한 뒤 변환 (`scripts/convert_qwen3map.sh`).

이 과정에서 원본의 SWA(sliding window attention, window 1024) 레이어 배치와 
YaRN rope 설정이 제거되어 전 레이어 full attention + 기본 rope로 동작한다:

- **~1024 토큰 이내 대화: 원본과 수학적으로 동일**
- **컨텍스트 4096 이하 사용 권장** (`-c 4096`)
- 짧은 대화 위주의 온디바이스 챗봇 용도에 적합

## 요구 사항

- Linux (또는 Colab), Python 3.10+
- git, cmake, C++ 컴파일러 (cmake가 없으면 `pip install cmake ninja`로 대체 가능)
- 디스크 여유 ~10GB (원본 ~2.6GB + f16 GGUF ~2.6GB + Q4_K_M ~0.85GB + 빌드)
- GPU 불필요 — 변환/양자화는 CPU만으로 동작

## 사용 방법

### 로컬 (Linux)

```bash
git clone https://github.com/ssolunar/kanana-quant.git
cd kanana-quant
bash scripts/quantize.sh          # 환경 구성 → llama.cpp 빌드 → 모델 다운로드
                                  # ([4/6] 변환 단계는 아키텍처 미지원으로 실패함 — 정상)
bash scripts/convert_qwen3map.sh  # Qwen3 매핑 → f16 GGUF → Q4_K_M 양자화 → 스모크 테스트
```

### Colab

```python
!git clone https://github.com/ssolunar/kanana-quant.git
%cd kanana-quant
!bash scripts/quantize.sh
!bash scripts/convert_qwen3map.sh
```

완료되면 `Kanana-2-1.3b-instruct-Q4_K_M.gguf`(~0.85GB)가 생성됨.
llama.cpp / Ollama / LM Studio / PocketPal 등 GGUF 호환 런타임에서 사용:

```bash
./llama.cpp/build/bin/llama-cli -m Kanana-2-1.3b-instruct-Q4_K_M.gguf -cnv -c 4096
```

### Hugging Face 업로드 (선택)

```bash
bash scripts/upload_hf.sh <your-hf-username>   # 사전: hf auth login (write 토큰)
```

## 폴더 구성

- `scripts/quantize.sh` — 환경 구성, llama.cpp 빌드, 원본 모델 다운로드
- `scripts/convert_qwen3map.sh` — Qwen3 아키텍처 매핑 변환 + Q4_K_M 양자화 (핵심)
- `scripts/upload_hf.sh` — 양자화 모델 + 라이선스 문서 HF 업로드
- `release/` — 배포 동반 파일 (MODEL_CARD, NOTICE, LICENSE)
- `test/prompts.txt` — 양자화 전후 품질 비교용 한국어 테스트 프롬프트

## 라이선스

원본 모델과 양자화 모델(Derivative Work)은 **Kanana Open License Agreement**를 따름
([release/LICENSE](release/LICENSE)). 재배포 시 의무 사항:

- 모델명에 `Kanana-` 접두어 유지
- LICENSE 전문·NOTICE 파일 동봉, "Powered by Kanana" 표시
- 수정(양자화) 사실 명시, Responsible AI 가이드라인 적용 고지

모델을 **임베드한 제품을 제3자에게 제공**하는 것은 라이선스 §4.1(iii)에 따라
KAKAO의 별도 상업 라이선스 대상이 될 수 있음.
