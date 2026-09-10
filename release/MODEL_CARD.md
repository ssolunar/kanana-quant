---
base_model: kakaocorp/kanana-2-1.3b-instruct
license: other
license_name: kanana-open-license
license_link: LICENSE
language:
  - ko
  - en
pipeline_tag: text-generation
tags:
  - gguf
  - llama.cpp
  - quantized
  - q4_k_m
  - kanana
---

# Kanana-2-1.3B-Instruct — Q4_K_M GGUF

**Powered by Kanana**

[kakaocorp/kanana-2-1.3b-instruct](https://huggingface.co/kakaocorp/kanana-2-1.3b-instruct)를
llama.cpp로 **Q4_K_M(4bit) GGUF** 양자화한 모델입니다. 온디바이스(모바일) 추론용으로 제작되었습니다.

## 수정 내역 (Modifications)

- 원본 BF16 가중치를 GGUF f16으로 변환 후 `llama-quantize`로 Q4_K_M 양자화
- llama.cpp가 `Kanana2Tiny` 아키텍처를 지원하지 않아, config의 아키텍처를 `Qwen3ForCausalLM`으로
  매핑하여 변환함 (가중치 자체는 원본 그대로)
- 양자화 수행: ssolunar, 2026-09

### ⚠️ 아키텍처 매핑에 따른 제약

원본 모델의 SWA(sliding window attention, window 1024) 레이어 배치와 full-attention 레이어의
YaRN rope 설정이 변환 과정에서 제거되고 전 레이어 full attention + 기본 rope로 동작합니다.

- **~1024 토큰 이내 대화: 원본과 수학적으로 동일**
- **컨텍스트 4096 이하 사용 권장** (`-c 4096`) — 그 이상에서는 원본 대비 품질 저하 가능
- 짧은 대화 위주의 온디바이스 챗봇 용도에 적합

## 파일

| 파일 | 양자화 | 크기(약) |
|---|---|---|
| Kanana-2-1.3b-instruct-Q4_K_M.gguf | Q4_K_M | ~0.85GB |

## 사용 방법

llama.cpp / Ollama / LM Studio / PocketPal 등 GGUF 호환 런타임에서 로드:

```
llama-cli -m Kanana-2-1.3b-instruct-Q4_K_M.gguf -cnv
```

Galaxy S20 FE(6GB RAM)급 기기에서 CPU 추론으로 동작 확인됨. <!-- 실측 후 tok/s 기입 -->

## 라이선스 및 사용 제한

이 모델은 **Kanana Open License Agreement**의 파생 모델(Derivative Work)입니다.

- 전문: 동봉된 [LICENSE](./LICENSE) 파일 참조
- 사용 시 KAKAO의 **Guidelines For Responsible AI**(금지 사용 정책)가 적용되며,
  재배포 시 후속 사용자에게 동일한 제한이 적용됨을 고지해야 합니다.
- API/클라우드 서비스 제공, SI/온프레미스 납품, **온디바이스 임베드 제품의 제3자 제공**은
  KAKAO의 별도 상업 라이선스가 필요할 수 있습니다 (License §4.1).

Copyright © KAKAO Corp. All Rights Reserved.
