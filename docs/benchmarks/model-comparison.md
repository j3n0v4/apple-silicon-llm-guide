# Model Comparison

Benchmark data for all models tested on the MacBook Pro M1 Max (64 GB) — see the [Methodology](methodology.md) page for hardware configuration and measurement approach. Measurements were taken via `/api/generate` (raw generation endpoint) unless otherwise noted.

## Quick reference table

| Model | Throughput | Quality | Disk Size | KV Cache (128K) | Cold Start | RAM Budget |
|-------|-----------|---------|-----------|-----------------|------------|------------|
| gemma4:e2b-nvfp4 | **93.1 tok/s** | 9/10 | 6.5 GB | ~0.3 GB | **1.51s** | ~6.8 GB |
| gemma4:e4b-mxfp8 | 63.0 tok/s | 8/10 | 11 GB | ~0.5 GB | 3.0s | ~11.5 GB |
| gemma4:e4b-nvfp4 | 60.4 tok/s | 8/10 | 8.8 GB | ~0.5 GB | 2.0s | ~9.3 GB |
| qwen3-coder:30b | 55.7 tok/s | **10/10** | 18 GB | 15.2 GB | 7.8s | ~33 GB |
| qwen3.6:35b-a3b-nvfp4 | 54.3 tok/s | 9/10 | 21 GB | 1.25 GB | 5.0s | ~22 GB |
| qwen3.6:35b-a3b-coding-nvfp4 | 53.9 tok/s | **10/10** | 21.9 GB | 1.25 GB | 2.68s | ~23 GB |
| gemma4:26b-nvfp4 | 52.8 tok/s | 9/10 | 17 GB | 1.92 GB | 3.4s | ~19 GB |
| gemma4:12b-nvfp4 | 28.7 tok/s | 9/10 | 7.7 GB | ~1.5 GB | 2.1s | ~9.2 GB |
| deepseek-r1:14b | 22.2 tok/s | **10/10** | 9.0 GB | 40 GB | 2.79s | ~49 GB |

!!! info "Table columns"
    - **Throughput:** Tokens per second during generation (prefill excluded). Higher is better.
    - **Quality:** Subjective quality score (1–10) based on reasoning, coherence, and instruction following.
    - **Disk Size:** Model file size on disk in the stated quantization.
    - **KV Cache:** Memory consumed by the key-value cache at 128K context length.
    - **RAM Budget:** Total memory required (model + KV cache + overhead). Must fit in your available RAM.
    - **Cold Start:** Time from request to first token (includes model load if not cached).

## Model profiles

### Gemma 4 Family

Google's Gemma 4 models are the standout performers on Apple silicon, thanks to their efficient architecture and excellent MLX quantization support.

| Model | Best For | Why |
|-------|----------|-----|
| gemma4:e2b-nvfp4 | **Maximum speed** | 93.1 tok/s — fastest model tested. Great for chat, summarization, and high-throughput tasks. |
| gemma4:e4b-nvfp4 | **Balanced general use** | 60.4 tok/s with 8/10 quality. Excellent cold start (2.0s). Pairs well with other models. |
| gemma4:e4b-mxfp8 | **Higher precision** | 63.0 tok/s with MXFP8 quantization. Slightly better quality than NVFP4 at the cost of larger disk footprint. |
| gemma4:26b-nvfp4 | **Deep reasoning** | 52.8 tok/s at 9/10 quality. The largest Gemma 4 variant — best for complex reasoning tasks. |
| gemma4:12b-nvfp4 | **Memory-constrained** | 28.7 tok/s but only 7.7 GB disk. Good for systems with limited free memory. |

### Qwen 3.6 Family

Alibaba's Qwen models offer strong performance, especially for coding and structured tasks.

| Model | Best For | Why |
|-------|----------|-----|
| qwen3.6:35b-a3b-nvfp4 | **MoE efficiency** | 35B total params, only 3B active. 54.3 tok/s at 9/10 quality. Excellent memory efficiency. |
| qwen3.6:35b-a3b-coding-nvfp4 | **Coding MoE** | Same architecture tuned for code. 53.9 tok/s at 10/10 quality. Faster cold start (2.68s) than the general variant. |
| qwen3-coder:30b | **Best coder** | 55.7 tok/s at 10/10 quality. Dense 30B model — no MoE overhead. Best tool calling support. |

### DeepSeek R1

| Model | Best For | Why |
|-------|----------|-----|
| deepseek-r1:14b | **Reasoning / thinking** | 10/10 quality with chain-of-thought reasoning. Slowest at 22.2 tok/s and massive KV cache (40 GB at 128K). |

## Cold start comparison


Cold start time is the delay from sending a request to receiving the first token. This includes model loading (if not cached in memory), prompt processing, and prefill.

| Model | Cold Start | Notes |
|-------|-----------|-------|
| gemma4:e2b-nvfp4 | **1.51s** | Fastest — tiny model, quick to load |
| gemma4:e4b-nvfp4 | 2.0s | |
| gemma4:12b-nvfp4 | 2.1s | |
| qwen3.6:35b-a3b-coding-nvfp4 | 2.68s | |
| deepseek-r1:14b | 2.79s | Fast load despite large KV cache |
| gemma4:26b-nvfp4 | 3.4s | |
| gemma4:e4b-mxfp8 | 3.0s | MXFP8 is slower to load than NVFP4 |
| qwen3.6:35b-a3b-nvfp4 | 5.0s | |
| qwen3-coder:30b | 7.8s | Largest dense model — slowest cold start |

## API overhead

All measurements above use `/api/generate` (raw generation endpoint). Using `/v1/chat/completions` (OpenAI-compatible chat endpoint) adds **33–37% overhead** to generation time:

| Endpoint | Throughput (gemma4:e4b-nvfp4) | Overhead |
|----------|-------------------------------|----------|
| `/api/generate` | 60.4 tok/s | — |
| `/v1/chat/completions` | ~40 tok/s | ~33% slower |

This overhead comes from chat template processing, token counting, and response formatting. For maximum throughput, prefer `/api/generate` when your workflow does not need chat formatting.

## Recommendations by use case

| Use Case | Recommended Model | Why |
|----------|-----------------|-----|
| **Chat / General** | gemma4:e4b-nvfp4 | 60.4 tok/s, 2.0s cold start, 9.3 GB budget |
| **High-throughput** | gemma4:e2b-nvfp4 | 93.1 tok/s, tiny footprint |
| **Coding** | qwen3-coder:30b | 10/10 quality, best tool calling |
| **Coding (memory-limited)** | qwen3.6:35b-a3b-coding-nvfp4 | 10/10 quality, MoE efficiency |
| **Reasoning** | deepseek-r1:14b | 10/10 quality, chain-of-thought |
| **Deep reasoning** | gemma4:26b-nvfp4 | 9/10 quality, 52.8 tok/s |
| **Multi-model** | gemma4:e4b-nvfp4 + qwen3-coder:30b | Best pair for 64 GB (see [Co-Residence](co-residence.md)) |
