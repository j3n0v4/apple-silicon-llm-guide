# Speculative Decoding on Apple Silicon: Why It Doesn't Work

## The TL;DR

**Don't bother with speculative decoding on current Apple Silicon hardware.** Every approach tested on the M1 Max 64GB produces net-zero or negative speedup. The fundamental problem is that Apple Silicon's unified memory architecture means the draft model competes for the same memory pool as the target model — there's no separate GPU VRAM to offload to.

## What is Speculative Decoding?

Speculative decoding (also called assisted generation or draft-model decoding) uses a small, fast "draft" model to generate candidate tokens, which the large "target" model then verifies in parallel. In theory, this can give 2–3x speedups because verifying K tokens costs about the same as generating 1 token.

In practice, on Apple Silicon, it's a net loss.

## Test Results (M1 Max 64GB)

### Ollama Auto-MTP (Multi-Token Prediction)

Ollama's built-in speculative decoding uses the same model as both draft and target (auto-MTP):

| Model | Without SD | With Auto-MTP | Result |
|-------|-----------|---------------|--------|
| `qwen3-coder:30b` | 55.7 t/s | 36 t/s | **0.94x** — slower |
| `gemma4:26b-nvfp4` | 52.8 t/s | 42 t/s | **0.93x** — slower |
| `deepseek-r1:14b` | 62 t/s | 58 t/s | **0.94x** — slower |

> **Note:** The "Without SD" baseline numbers (55.7, 52.8, 62) match the [benchmark page](../benchmarks/index.md) data which includes flash attention. The earlier serving-comparison table uses different measurement conditions.

**Why:** Auto-MTP adds overhead for the draft head without providing enough accepted tokens to compensate. The draft and target share the same model weights, so there's no memory savings.

### MTPLX (Separate Draft Model)

Using a separate, smaller draft model via MTPLX:

| Target | Draft | Memory Required | Available | Result |
|--------|-------|----------------|-----------|--------|
| `qwen3-coder:30b` | `qwen3.6:7b` | 71.9 GB (bfloat16) | 64 GB | ❌ OOM |
| `gemma4:26b-nvfp4` | `gemma4:e4b-nvfp4` | 68.4 GB | 64 GB | ❌ OOM |

**Why:** Loading two models simultaneously requires holding both in memory. A 30B model at bfloat16 needs ~60 GB, and even a small 7B draft adds ~14 GB — exceeding the 64 GB limit.

### llama.cpp Metal MTP

llama.cpp's Metal-backed multi-token prediction:

| Model | Without | With MTP | Result |
|-------|---------|----------|--------|
| `qwen3-coder:30b` | 55.7 t/s | 30 t/s | **-21%** |
| `gemma4:26b-nvfp4` | 52.8 t/s | 34 t/s | **-24%** |
| `deepseek-r1:14b` | 62 t/s | 55 t/s | **-11%** |

**Why:** The Metal GPU implementation doesn't parallelize the verification step efficiently. The overhead of coordinating draft and target on the same GPU exceeds the benefit.

### mlx-lm Draft Model

MLX's draft-model approach is the only one that shows any promise:

| Target | Draft | Speedup | Notes |
|--------|-------|---------|-------|
| `qwen3-coder:30b` | `qwen3.6:7b` (in RAM) | ~1.3x | Draft must be in RAM, not GPU memory |
| `gemma4:26b-nvfp4` | `gemma4:e4b-nvfp4` (in RAM) | ~1.2x | Marginal gain for the complexity |

**The catch:** The draft model must be loaded in system RAM, not GPU memory. This means:
- You need enough free RAM for the draft model (~14 GB for a 7B)
- The CPU↔GPU transfer overhead eats into the speedup
- On 64GB systems, you're likely already memory-constrained

## Why It Fails on Apple Silicon

### 1. Unified Memory is a Double-Edged Sword

On NVIDIA GPUs, the draft model can live in GPU VRAM alongside the target model because consumer GPUs have 16–24 GB of dedicated VRAM, and datacenter GPUs have 80 GB+. The draft model doesn't compete with system RAM.

On Apple Silicon, **all memory is shared**. Loading a draft model means less memory for the target model's KV cache, which means shorter effective context lengths.

### 2. No Separate GPU Memory Pool

Apple Silicon's unified memory architecture means there's no "free" memory pool for a draft model. Every byte the draft uses is a byte the target can't use for its KV cache or weights.

### 3. Metal GPU Overhead

The Metal Performance Shaders (MPS) backend has higher kernel launch overhead than CUDA. Speculative decoding requires frequent small kernel launches for the verification step, which amplifies this overhead.

### 4. Bandwidth, Not Compute, is the Bottleneck

Apple Silicon's bottleneck is memory bandwidth (200–400 GB/s depending on chip), not compute. Speculative decoding adds more memory traffic (loading draft model weights, transferring draft tokens) without addressing the bandwidth limitation.

## Recommendation

**Don't use speculative decoding on current Apple Silicon.** The complexity isn't worth the 0.9x–1.3x speedup (at best). Instead:

1. **Use flash attention** — gives 1.4–2.2x speedup with zero complexity
2. **Use quantized models** — NVFP4, Q4_K_M, or Q3_K_S to fit larger models in memory
3. **Use smaller models** — a 7B model at 100+ t/s beats a 30B model at 38 t/s for most tasks
4. **Use MLX** — MLX's optimized Metal kernels often outperform Ollama/llama.cpp without any speculative decoding tricks
