# Apple Silicon LLM Guide

<div class="hero" markdown="1">

## Run LLMs on your Mac — fast, local, and free

A reference for running large language models on Apple silicon
(M1, M2, M3, M4). I bought a MacBook Pro M1 Max and wanted to find the best
local LLM setup for the hardware — this project shares what I learned along the way.

</div>

---

## TL;DR — what should I pick?

**Just want the answer? Here are the best choices for M1 Max 64 GB:**

| Use Case | Pick This | Why |
|----------|-----------|-----|
| **Daily chat** | `gemma4:e4b-nvfp4` via Ollama | 60.4 tok/s, 8/10 quality, easiest setup |
| **Max speed** | `gemma4:e2b-nvfp4` via Ollama | 93.1 tok/s, 9/10 quality, fastest model tested |
| **Coding assistant** | `qwen3-coder:30b` via Ollama | 55.7 tok/s, 10/10 quality, best code model |
| **MoE sweet spot** | `qwen3.6:35b-a3b-nvfp4` via Ollama | 54.3 tok/s, only 3B active params, great throughput |
| **Small & fast** | `gemma4:e4b-nvfp4` via Ollama | 60.4 tok/s, 8/10 quality, fits in 16 GB |
| **Reasoning** | `deepseek-r1:14b` via Ollama | 10/10 quality, but 40 GB KV cache — memory-hungry |
| **Serving engine** | **Ollama** for daily use, **oMLX** for max speed, **Rapid-MLX** for batch | See [Serving Comparison](architecture/serving-comparison.md) |
| **Quantization** | **NVFP4** default, **Q4_K_M** on Ollama, **Q8_0** if quality matters | See [Quantization Guide](benchmarks/quantization.md) |
| **MLX engine** | **oMLX** for chat/agents, **Rapid-MLX** for long generation | See [MLX Engines](benchmarks/mlx-engines.md) |

**Install in 60 seconds:**

```bash
curl -fsSL https://ollama.com/install.sh | sh   # Install Ollama
ollama pull gemma4:e4b-nvfp4                      # Pull the best all-around model
ollama run gemma4:e4b-nvfp4                        # Start chatting
```

---

<div class="grid cards" markdown>

-   **Benchmarks**

    ---

    Real-world token-generation speeds for dozens of models. Compare
    quantization levels, MLX engines, and hardware configurations.

    [View Benchmarks →](benchmarks/index.md)

-   **Getting Started**

    ---

    From zero to inference in five minutes. Install Ollama, pull a model,
    and start generating.

    [Get Started →](getting-started.md)

-   **Setup Guides**

    ---

    Step-by-step instructions for Ollama, MLX, Open WebUI,
    and memory management.

    [Browse Guides →](guides/ollama-setup.md)

-   **Workarounds**

    ---

    Documented fixes for known issues: the `/no_think` bug, context-length
    footguns, thinking-model quirks, and flash attention tuning.

    [See Workarounds →](workarounds/no-think-bug.md)

-   **Architecture Patterns**

    ---

    Design systems that burst inference on local hardware and manage
    memory efficiently.

    [Explore Patterns →](architecture/burst-unload.md)

-   **References**

    ---

    Official project sites, research papers, model publishers, and
    quantization references.

    [Full References →](references.md)

</div>

---

## Hardware note

> **Tested on:** MacBook Pro M1 Max (64 GB). See the [Methodology page](benchmarks/methodology.md) for full hardware specs and measurement approach. Results scale to other M-series chips by memory bandwidth and GPU core count.

---

## What's inside

### Benchmarks

Performance data covering:

- **Model comparison** — Token-generation speeds for Gemma, Qwen, Llama,
  DeepSeek, Mistral, Phi, and other model families across quantization levels.
- **MLX engine benchmarks** — Compare mlx-lm, Rapid-MLX, and oMLX on the same
  hardware.
- **Quantization guide** — GGUF, NVFP4, MXFP8, Q4_K_M, and more — what they
  mean and when to use each.
- **Co-residence guide** — Running multiple models simultaneously on limited
  memory.
- **Tool calling** — Structured output and function-calling performance.

### Setup Guides

- **Ollama** — Install, configure, pull models, serve, and integrate.
- **MLX** — Apple's machine learning framework for Apple silicon.
- **Open WebUI** — A ChatGPT-like interface for local models.

- **Model selection** — How to choose the right model for your hardware and
  use case.
- **Memory management** — Tuning KV cache, context length, and concurrent
  model loading.

### Workarounds

- **`/no_think` bug** — Fix for models that get stuck in thinking mode.
- **Swap impact** — Stale swap costs 30%+ tok/s. How to detect, purge, and prevent it.
- **Context length footgun** — Why your model slows down and how to fix it.
- **Thinking models** — Running DeepSeek R1, QwQ, and other reasoning models.
- **Flash attention** — Enabling and tuning flash attention on Apple silicon.
- **Speculative decoding** — Speed up inference with draft models.

### Architecture Patterns

- **Burst & Unload** — Load a model, run inference, unload — for batch
  processing and serverless-style workloads.
- **Serving comparison** — Ollama vs. MLX vs. llama.cpp on Apple silicon.

---

## Test hardware

All benchmarks and instructions in this project were tested on a **MacBook Pro (2021) with Apple M1 Max** — 10-core CPU (8 performance + 2 efficiency), 24-core GPU, 64 GB unified memory, 2 TB SSD. See the [Benchmark Methodology](benchmarks/methodology.md) page for the complete hardware configuration, software versions, and measurement approach.

> **Compatibility:** Results scale to other M-series chips by memory bandwidth and GPU core count. M2/M3/M4 chips with equivalent or better specs will match or exceed these numbers.

---

## Community

This project is maintained at
[r/LocalLLaMA](https://reddit.com/r/LocalLLaMA). Contributions, corrections,
and new benchmark data are always welcome.

- **GitHub**: [j3n0v4/apple-silicon-llm-guide](https://github.com/j3n0v4/apple-silicon-llm-guide)
- **Reddit**: [r/LocalLLaMA](https://reddit.com/r/LocalLLaMA)
- **License**: MIT — free to use, share, and contribute to.
