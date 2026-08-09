# Quantization Guide

> **Recommendation:** Use **NVFP4** as your default — best quality-to-speed tradeoff, MLX-native, fastest cold start. Use **Q4_K_M** if you are on Ollama (it is the default GGUF quant). Use **Q8_0** only when quality is critical and you have memory to spare.

Quantization reduces model precision to fit in memory and improve throughput. This page compares all major quantization formats available on Apple Silicon.

## Quantization formats overview

| Format | Framework | Bits | Type | Perplexity | Speed | File Size |
|--------|-----------|------|------|-----------|-------|-----------|
| **NVFP4** | MLX | 4-bit | Block floating point | **17.95** | Fastest | Small |
| **MXFP8** | MLX | 8-bit | Microscaling float | ~17.6 | Moderate | Large |
| **MXFP4** | MLX | 4-bit | Microscaling float | ~18.0 | Moderate | Medium |
| **4bit-MLX** | MLX | 4-bit | Native MLX quant | ~18.0 | Fast | Small |
| **Q4_K_M** | llama.cpp | 4-bit | K-quant | 18.36 | Fast | Small |
| **Q8_0** | llama.cpp | 8-bit | Block quant | ~17.6 | Moderate | Large |

## Perplexity comparison

Perplexity (lower is better) measured on a held-out validation set, with BF16 as the baseline:


| Format | Perplexity | vs BF16 | Quality Impact |
|--------|-----------|---------|----------------|
| BF16 (baseline) | 17.54 | — | Reference |
| MXFP8 | ~17.6 | +0.06 | Negligible |
| Q8_0 | ~17.6 | +0.06 | Negligible |
| NVFP4 | 17.95 | +0.41 | Minimal |
| 4bit-MLX | ~18.0 | +0.46 | Minimal |
| MXFP4 | ~18.0 | +0.46 | Minimal |
| Q4_K_M | 18.36 | +0.82 | Noticeable |

## Speed comparison


### Small Models (< 12B params)

| Format | Throughput (gemma4:e4b) | Cold Start |
|--------|------------------------|------------|
| NVFP4 | **60.4 tok/s** | **2.0s** |
| MXFP8 | 63.0 tok/s | 3.0s |
| MXFP4 | ~55 tok/s | ~3.5s |

For small models, **MXFP8 is actually faster than NVFP4** — the extra precision does not cost much on small parameter counts.

### Large Models (≥ 12B params)

| Format | Throughput (gemma4:26b) | Cold Start |
|--------|------------------------|------------|
| NVFP4 | **52.8 tok/s** | **3.4s** |
| MXFP8 | ~45 tok/s | ~5s |
| MXFP4 | ~48 tok/s | ~4.5s |

For large models, **NVFP4 is the clear winner** — MXFP8's higher precision comes with a significant speed penalty.

## File size comparison

| Format | gemma4:e4b (8B) | gemma4:26b (26B) | qwen3-coder:30b (30B) |
|--------|-----------------|------------------|----------------------|
| BF16 | ~16 GB | ~52 GB | ~60 GB |
| MXFP8 | 11 GB | ~35 GB | ~40 GB |
| NVFP4 | **8.8 GB** | **17 GB** | **18 GB** |
| MXFP4 | ~9 GB | ~18 GB | ~19 GB |
| Q4_K_M | ~5 GB | ~15 GB | ~16 GB |
| Q8_0 | ~9 GB | ~28 GB | ~30 GB |

!!! note "llama.cpp vs MLX file sizes"
    llama.cpp's Q4_K_M produces smaller files than MLX's NVFP4 because it uses a different quantization scheme. However, NVFP4 has better perplexity (17.95 vs 18.36) and runs natively on MLX without conversion overhead.

## When to use each format

### NVFP4 — Recommended Default

**Use NVFP4 for:** Most users, most models, most of the time.

- MLX-native 4-bit block floating point
- Best perplexity-to-speed tradeoff (17.95)
- Fastest cold start for large models
- Excellent tool calling support
- Supported by all MLX engines (mlx_lm, Rapid-MLX, oMLX)

```bash
# Convert to NVFP4
mlx_lm.convert --model <model> --quantize nvfp4
```

### MXFP8 — When Quality Matters Most

**Pick MXFP8 for:** Small models where you want maximum quality and have memory to spare.

- 8-bit microscaling float — closest to BF16 quality
- Actually faster than NVFP4 on small models (< 12B params)
- 2x the file size of NVFP4
- Slower than NVFP4 on large models

```bash
mlx_lm.convert --model <model> --quantize mxfp8
```

### MXFP4 — The Middle Ground

**MXFP4 shines when:** You want 4-bit efficiency but need slightly different quantization behavior.

- Similar quality to NVFP4
- Larger model files than NVFP4
- Slower cold start than NVFP4
- Not widely tested — use NVFP4 instead unless you have a specific reason

```bash
mlx_lm.convert --model <model> --quantize mxfp4
```

### 4bit-MLX — mlx_lm Native

**Choose 4bit-MLX when:** Using mlx_lm's built-in quantization.

- mlx_lm's native 4-bit format
- Similar quality to NVFP4
- Slightly different quantization behavior
- Use when the model is already in 4bit-MLX format from Hugging Face

```bash
# Load a pre-quantized 4bit-MLX model
mlx_lm.server --model Qwen3.5-35B-A3B-abliterated-4bit
```

### Q4_K_M — llama.cpp K-Quant

**Q4_K_M works best with:** Ollama (which uses llama.cpp under the hood).

- llama.cpp's 4-bit K-quant
- Smallest file sizes
- Slightly lower quality (perplexity 18.36 vs NVFP4's 17.95)
- Good for memory-constrained scenarios
- Supported by Ollama out of the box

```bash
# Pull a Q4_K_M quantized model in Ollama
ollama pull gemma4:e4b-q4_K_M
```

### Q8_0 — llama.cpp 8-Bit

**Reach for Q8_0 when:** You want maximum quality in Ollama and have memory to spare.

- llama.cpp's 8-bit block quantization
- Near-lossless quality (~17.6 perplexity)
- 2x memory of Q4_K_M
- Good for critical tasks where quality matters most

```bash
ollama pull gemma4:e4b-q8_0
```

## Quantization decision flowchart


## Summary

| Priority | Recommended Format | Why |
|----------|-------------------|-----|
| **Best all-around** | NVFP4 | Best perplexity-to-speed tradeoff, MLX-native |
| **Maximum quality (MLX)** | MXFP8 | Near-lossless, fast on small models |
| **Maximum quality (Ollama)** | Q8_0 | Near-lossless, 8-bit block quantization |
| **Smallest file size** | Q4_K_M | Smallest disk footprint |
| **Best for large models** | NVFP4 | Fastest cold start and throughput for 12B+ |
| **Best for small models** | MXFP8 | Faster than NVFP4 on sub-12B models |
