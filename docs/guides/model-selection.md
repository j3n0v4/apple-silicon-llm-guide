# Model Selection Guide

> **Tested hardware:** MacBook Pro M1 Max (64 GB) — see the [Benchmark Methodology](../benchmarks/methodology.md) for the complete hardware configuration. All benchmark data in this guide was measured on this exact machine. The 128 GB+ tier recommends models that **don't fit in 64 GB** — these are based on community reports, not my testing. Results scale to other M-series chips by memory bandwidth and GPU core count.

Choosing the right model depends on your available RAM. Use this guide to pick the right model for your hardware.

## RAM Tiers

| RAM | Typical Macs | What You Can Run |
|-----|-------------|-----------------|
| **8 GB** | M1/M2 MacBook Air, Mac mini | 1-3B models, heavily quantized 7B |
| **16 GB** | M1/M2/M3 Pro, MacBook Air | 7B-9B models, small MoE models |
| **32 GB** | M1/M2/M3 Pro/Max | 14B-30B models, most MoE models |
| **64 GB** | M1/M2/M3/M4 Max/Ultra | 30B-70B models, large MoE models |
| **128 GB+** | M2/M4 Ultra | 70B-120B models, multiple models |

## Model Size Categories

### By Parameter Count

| Size | Examples | RAM Needed (Q4) | RAM Needed (Q8) | Use Case |
|------|---------|---------------|---------------|---------|
| **1-3B** | Gemma 4 2B, Qwen 3 0.5B | 2-4 GB | 3-6 GB | Simple Q&A, classification |
| **7-9B** | Gemma 4 9B, Qwen 3 Coder 7B | 6-10 GB | 10-16 GB | General purpose, code |
| **14B** | DeepSeek R1 14B, Qwen 3 14B | 10-16 GB | 18-24 GB | Reasoning, analysis |
| **24-30B** | Gemma 4 26B, Qwen 3 Coder 30B | 18-28 GB | 32-48 GB | Complex reasoning, coding |
| **70B** | Llama 3.3 70B, Qwen 3 72B | 40-50 GB | 70-90 GB | Maximum capability |
| **120B+** | Qwen 3 235B | 80-120 GB | 140-200 GB | Frontier-level (128 GB+ only) |

### MoE (Mixture of Experts) Models

MoE models have **active parameters** (used per token) and **total parameters** (stored in memory). The active count determines speed; the total count determines memory.

| Model | Total Params | Active Params | RAM Needed (Q4) | Speed |
|-------|-------------|--------------|---------------|-------|
| Qwen 3 Coder 14B-A3B | 14B | 3B | 10-14 GB | Very fast |
| Qwen 3 30B-A3B | 30B | 3B | 18-24 GB | Very fast |
| DeepSeek R1 14B | 14B | 14B (dense) | 10-16 GB | Moderate |
| Qwen 3 72B-A14B | 72B | 14B | 40-50 GB | Fast |

**MoE advantage**: MoE models give you the capability of a large model with the speed of a small one. The 30B-A3B model (30B total, 3B active) runs nearly as fast as a 3B model while delivering quality closer to a 30B model.

## KV Cache Memory Calculation

The KV cache is the hidden state stored during generation. It grows with context length and is a major memory consumer.

### Formula

```
KV Cache Size = context_length × num_layers × kv_heads × head_dim × bytes_per_element × 2 (K + V)
```

For Q8_0 quantization (1 byte per element):

```
KV Cache (GB) = context_length × num_layers × kv_heads × head_dim × 2 / 1,073,741,824
```

### Example Calculations

| Model | Layers | KV Heads | Head Dim | KV Cache at 4K ctx | KV Cache at 32K ctx |
|-------|--------|---------|---------|-------------------|--------------------|
| Gemma 4 9B | 42 | 8 | 128 | 0.3 GB | 2.6 GB |
| Gemma 4 26B | 62 | 16 | 128 | 0.9 GB | 7.6 GB |
| Qwen 3 Coder 14B | 40 | 8 | 128 | 0.3 GB | 2.4 GB |
| Qwen 3 Coder 30B | 62 | 8 | 128 | 0.5 GB | 3.8 GB |
| Llama 3.3 70B | 80 | 8 | 128 | 0.6 GB | 4.8 GB |

### Practical Impact

- **Short context (1-4K)**: KV cache is negligible (< 0.5 GB)
- **Medium context (8-16K)**: KV cache is noticeable (0.5-2 GB)
- **Long context (32-128K)**: KV cache dominates memory (2-16 GB)
- **Extreme context (1M+)**: Requires flash attention and aggressive quantization

## Quantization Impact on Memory

See the [Quantization Guide](../benchmarks/quantization.md) for a complete comparison of all formats including perplexity, speed, and file size.

| Quantization | Memory vs FP16 | Quality Loss |
|-------------|---------------|-------------|
| **FP16** | 100% (baseline) | None |
| **Q8_0** | 50% | Minimal |
| **Q4_K_M** | 28% | Small |
| **Q4_0** | 25% | Moderate |
| **Q3_K_M** | 22% | Noticeable |
| **Q2_K** | 16% | Significant |
| **NVFP4** | 25% | Small (MLX format) |

### Memory Calculation for a 9B Model

| Quantization | Model Weights | KV Cache (4K) | Total (approx) |
|-------------|-------------|---------------|---------------|
| FP16 | 18 GB | 0.3 GB | 18.3 GB |
| Q8_0 | 9 GB | 0.3 GB | 9.3 GB |
| Q4_K_M | 5 GB | 0.3 GB | 5.3 GB |
| Q4_0 | 4.5 GB | 0.3 GB | 4.8 GB |

## Recommended Models Per RAM Tier

> **Benchmarked tier:** MacBook Pro M1 Max (64 GB). All models that fit in ≤64 GB RAM have verified performance data. The 128 GB+ tier is unbenchmarked — models there need more RAM than I have.

### 8 GB RAM

| Model | Quant | Format | Notes |
|-------|-------|--------|-------|
| Gemma 4 2B | NVFP4 | MLX/Ollama | Fast, capable for its size |
| Qwen 3 Coder 0.5B | Q8_0 | GGUF | Tiny, fast code completion |
| Qwen 3 1.7B | Q4_K_M | GGUF | General purpose |
| Gemma 4 9B | Q4_0 | GGUF | Tight fit, swaps |

### 16 GB RAM

| Model | Quant | Format | Notes |
|-------|-------|--------|-------|
| Gemma 4 9B | Q4_K_M | GGUF/MLX | Sweet spot |
| Qwen 3 Coder 7B | Q8_0 | GGUF/MLX | Excellent code model |
| Qwen 3 7B | Q8_0 | GGUF/MLX | Good general purpose |
| DeepSeek R1 14B | Q4_K_M | GGUF | Reasoning, tight fit |
| Qwen 3 Coder 14B-A3B | Q4_K_M | GGUF/MLX | MoE, very fast |

### 32 GB RAM

| Model | Quant | Format | Notes |
|-------|-------|--------|-------|
| Gemma 4 9B | BF16 | MLX | Full quality |
| Gemma 4 26B | Q4_K_M | GGUF/MLX | Strong reasoning |
| Qwen 3 Coder 14B-A3B | Q8_0 | GGUF/MLX | Fast, high quality code |
| Qwen 3 30B-A3B | Q4_K_M | GGUF/MLX | MoE, excellent quality |
| DeepSeek R1 14B | Q8_0 | GGUF | Full quality reasoning |
| Qwen 3 14B | Q8_0 | GGUF/MLX | Good general purpose |

### 64 GB RAM

| Model | Quant | Format | Notes |
|-------|-------|--------|-------|
| Gemma 4 26B | Q8_0 | GGUF/MLX | Excellent quality |
| Qwen 3 Coder 30B-A3B | Q8_0 | GGUF/MLX | Top-tier code model |
| Qwen 3 30B-A3B | Q8_0 | GGUF/MLX | Excellent general purpose |
| Llama 3.3 70B | Q4_K_M | GGUF | Tight fit, very capable |
| Qwen 3 72B-A14B | Q4_K_M | GGUF/MLX | MoE, fits well |
| DeepSeek R1 32B | Q4_K_M | GGUF | Strong reasoning |

### 128 GB+ RAM (M2/M4 Ultra — Not Benchmarked)

> **Note:** I only have benchmark data for M1 Max 64GB. The following recommendations are based on memory calculations and community reports, not my own testing.
>
> **Sources:** [CraftRigs M-series benchmarks](https://craftrigs.com), [WillItRun.AI](https://willitrunai.com), [r/LocalLLaMA community reports](https://reddit.com/r/LocalLLaMA)

| Model | Quant | Format | Notes |
|-------|-------|--------|-------|
| Llama 3.3 70B | Q8_0 | GGUF/MLX | Full quality |
| Qwen 3 72B-A14B | Q8_0 | GGUF/MLX | Excellent MoE |
| Qwen 3 235B-A14B | Q4_K_M | GGUF/MLX | Frontier-level |
| Multiple models | Various | Any | Run 2-3 models simultaneously |

## Decision Tree

```
How much RAM do you have?
│
├─ 8 GB
│   ├─ Need speed? → Gemma 4 2B (NVFP4)
│   └─ Need capability? → Gemma 4 9B (Q4_0, tight fit)
│
├─ 16 GB
│   ├─ General purpose? → Gemma 4 9B (Q4_K_M)
│   ├─ Code? → Qwen 3 Coder 7B (Q8_0) or 14B-A3B (Q4_K_M)
│   └─ Reasoning? → DeepSeek R1 14B (Q4_K_M)
│
├─ 32 GB
│   ├─ General purpose? → Qwen 3 30B-A3B (Q4_K_M) or Gemma 4 26B (Q4_K_M)
│   ├─ Code? → Qwen 3 Coder 14B-A3B (Q8_0) or 30B-A3B (Q4_K_M)
│   └─ Maximum quality? → Gemma 4 9B (BF16, full precision)
│
├─ 64 GB
│   ├─ General purpose? → Gemma 4 26B (Q8_0) or Qwen 3 30B-A3B (Q8_0)
│   ├─ Code? → Qwen 3 Coder 30B-A3B (Q8_0)
│   └─ Maximum capability? → Llama 3.3 70B (Q4_K_M)
│
└─ 128 GB+ (not benchmarked — see sources below)
    ├─ Single best model? → Qwen 3 235B-A14B (Q4_K_M)
    ├─ High quality? → Llama 3.3 70B (Q8_0)
    └─ Multi-model? → Run 2-3 models simultaneously
```

## Quick Selection by Use Case

> **⚡** = Unbenchmarked (models need >64 GB RAM). **64 GB** rows and below are backed by my [verified benchmarks](../benchmarks/model-comparison.md).

### Coding

| RAM | Best Choice |
|-----|------------|
| 8 GB | Qwen 3 Coder 0.5B (Q8_0) |
| 16 GB | Qwen 3 Coder 7B (Q8_0) or 14B-A3B (Q4_K_M) |
| 32 GB | Qwen 3 Coder 14B-A3B (Q8_0) or 30B-A3B (Q4_K_M) |
| 64 GB | Qwen 3 Coder 30B-A3B (Q8_0) |
| 128 GB+ ⚡ | Qwen 3 Coder 30B-A3B (BF16) |

Sources for ⚡ recommendations: [CraftRigs](https://craftrigs.com), [WillItRun.AI](https://willitrunai.com), [r/LocalLLaMA](https://reddit.com/r/LocalLLaMA)

### General Purpose / Chat

| RAM | Best Choice |
|-----|------------|
| 8 GB | Gemma 4 2B (NVFP4) |
| 16 GB | Gemma 4 9B (Q4_K_M) |
| 32 GB | Qwen 3 30B-A3B (Q4_K_M) |
| 64 GB | Gemma 4 26B (Q8_0) |
| 128 GB+ ⚡ | Qwen 3 72B-A14B (Q8_0) |

### Reasoning / Analysis

| RAM | Best Choice |
|-----|------------|
| 8 GB | Gemma 4 2B (NVFP4) |
| 16 GB | DeepSeek R1 14B (Q4_K_M) |
| 32 GB | Gemma 4 26B (Q4_K_M) |
| 64 GB | Gemma 4 26B (Q8_0) or DeepSeek R1 32B (Q4_K_M) |
| 128 GB+ ⚡ | Qwen 3 235B-A14B (Q4_K_M) |

## Next Steps

- [Memory Management](memory-management.md) — Deep dive into unified memory and KV cache
- [Ollama Setup](ollama-setup.md) — Install and configure Ollama
- [MLX Setup](mlx-setup.md) — Set up MLX for native Apple Silicon performance
