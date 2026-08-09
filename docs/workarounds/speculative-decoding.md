# Speculative Decoding on Apple silicon: Why It Does Not Work

## The TL;DR

**Skip speculative decoding on current Apple silicon hardware.** Every approach tested on the M1 Max 64GB produces net-zero or negative speedup. The fundamental problem is that Apple silicon unified memory architecture means the draft model competes for the same memory pool as the target model — there is no separate GPU VRAM to offload to.

## What is speculative decoding?

Speculative decoding (also called assisted generation or draft-model decoding) uses a small, fast "draft" model to generate candidate tokens, which the large "target" model then verifies in parallel. In theory, this can give 2–3x speedups because verifying K tokens costs about the same as generating 1 token.

In practice, on Apple silicon, it is a net loss.

## Test results (M1 Max 64GB)

### Ollama Auto-MTP (Multi-Token Prediction)

Ollama's built-in speculative decoding uses the same model as both draft and target (auto-MTP):

| Model | Without SD | With Auto-MTP | Result |
|-------|-----------|---------------|--------|
| `qwen3-coder:30b` | 55.7 tok/s | 36 tok/s | **0.94x** — slower |
| `gemma4:26b-nvfp4` | 52.8 tok/s | 42 tok/s | **0.93x** — slower |
| `deepseek-r1:14b` | 62 tok/s | 58 tok/s | **0.94x** — slower |

> **Note:** The `qwen3-coder:30b` (55.7) and `gemma4:26b-nvfp4` (52.8) "Without SD" baselines match the [benchmark page](../benchmarks/index.md) data (which includes flash attention). The `deepseek-r1:14b` baseline (62 tok/s) is a short-context measurement — its 128K-context benchmark is 22.2 tok/s. The earlier serving-comparison table uses different measurement conditions.

**Why:** Auto-MTP adds overhead for the draft head without providing enough accepted tokens to compensate. The draft and target share the same model weights, so there is no memory savings.

### MTPLX (Separate Draft Model)

Using a separate, smaller draft model via MTPLX:

| Target | Draft | Memory Required | Available | Result |
|--------|-------|----------------|-----------|--------|
| `qwen3-coder:30b` | `qwen3.6:7b` | 71.9 GB (bfloat16) | 64 GB | OOM |
| `gemma4:26b-nvfp4` | `gemma4:e4b-nvfp4` | 68.4 GB | 64 GB | OOM |

**Why:** Loading two models simultaneously requires holding both in memory. A 30B model at bfloat16 needs ~60 GB, and even a small 7B draft adds ~14 GB — exceeding the 64 GB limit.

### llama.cpp Metal MTP

llama.cpp's Metal-backed multi-token prediction:

| Model | Without | With MTP | Result |
|-------|---------|----------|--------|
| `qwen3-coder:30b` | 55.7 tok/s | 30 tok/s | **-21%** |
| `gemma4:26b-nvfp4` | 52.8 tok/s | 34 tok/s | **-24%** |
| `deepseek-r1:14b` | 62 tok/s | 55 tok/s | **-11%** |

**Why:** The Metal GPU implementation does not parallelize the verification step efficiently. The overhead of coordinating draft and target on the same GPU exceeds the benefit.

### mlx-lm Draft Model

MLX's draft-model approach is the only one that shows any promise:

| Target | Draft | Speedup | Notes |
|--------|-------|---------|-------|
| `qwen3-coder:30b` | `qwen3.6:7b` (in RAM) | ~1.3x | Draft must be in RAM, not GPU memory |
| `gemma4:26b-nvfp4` | `gemma4:e4b-nvfp4` (in RAM) | ~1.2x | Marginal gain for the complexity |

**The catch:** The draft model must be loaded in system RAM, not GPU memory. This means:
- You need enough free RAM for the draft model (~14 GB for a 7B)
- The CPU↔GPU transfer overhead eats into the speedup
- On 64GB systems, you are likely already memory-constrained

## Why it fails on Apple silicon

### 1. Unified Memory is a Double-Edged Sword

On NVIDIA GPUs, the draft model can live in GPU VRAM alongside the target model because consumer GPUs have 16–24 GB of dedicated VRAM, and datacenter GPUs have 80 GB+. The draft model does not compete with system RAM.

On Apple silicon, **all memory is shared**. Loading a draft model means less memory for the target model's KV cache, which means shorter effective context lengths.

### 2. No Separate GPU Memory Pool

Apple silicon unified memory architecture means there is no "free" memory pool for a draft model. Every byte the draft uses is a byte the target cannot use for its KV cache or weights.

### 3. Metal GPU Overhead

The Metal Performance Shaders (MPS) backend has higher kernel launch overhead than CUDA. Speculative decoding requires frequent small kernel launches for the verification step, which amplifies this overhead.

### 4. Bandwidth, Not Compute, is the Bottleneck

Apple silicon bottleneck is memory bandwidth (200–400 GB/s depending on chip), not compute. Speculative decoding adds more memory traffic (loading draft model weights, transferring draft tokens) without addressing the bandwidth limitation.

## Recommendation

**Avoid speculative decoding on current Apple silicon.** The complexity is not worth the 0.9x–1.3x speedup (at best). Instead:

1. **Use flash attention** — gives 1.4–2.2x speedup with zero complexity
2. **Use quantized models** — NVFP4, Q4_K_M, or Q3_K_S to fit larger models in memory
3. **Use smaller models** — a 7B model at 100+ tok/s beats a 30B model at 38 tok/s for most tasks
4. **Use MLX** — MLX's optimized Metal kernels often outperform Ollama/llama.cpp without any speculative decoding tricks
