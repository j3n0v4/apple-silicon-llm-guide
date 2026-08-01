# Apple Silicon LLM Guide

<div class="hero" markdown="1">

## Run LLMs on Your Mac — Fast, Local, and Free

A community-curated reference for running large language models on Apple Silicon
(M1, M2, M3, M4). I bought a MacBook Pro M1 Max and wanted to find the best
local LLM setup for the hardware — this guide shares what I learned along the way.

</div>

---

## ⚡ TL;DR — What Should I Pick?

**Just want the answer? Here are the best choices for M1 Max 64 GB:**

| Use Case | Pick This | Why |
|----------|-----------|-----|
| **Daily chat** | `gemma4:26b-nvfp4` via Ollama | 52.8 tok/s, 9/10 quality, easiest setup |
| **Coding assistant** | `qwen3-coder:30b` via Ollama | 55.7 tok/s, 10/10 quality, best code model |
| **Max speed / MoE** | `qwen3.6:35b-a3b-nvfp4` via Ollama | 54.3 tok/s, only 3B active params, great throughput |
| **Small & fast** | `gemma4:e4b-nvfp4` via Ollama | 60.4 tok/s, 8/10 quality, fits in 16 GB |
| **Reasoning** | `deepseek-r1:14b` via Ollama | 10/10 quality, but 40 GB KV cache — memory-hungry |
| **Serving engine** | **Ollama** for daily use, **oMLX** for max speed, **Rapid-MLX** for batch | See [Serving Comparison](architecture/serving-comparison.md) |
| **Quantization** | **NVFP4** default, **Q4_K_M** on Ollama, **Q8_0** if quality matters | See [Quantization Guide](benchmarks/quantization.md) |
| **MLX engine** | **oMLX** for chat/agents, **Rapid-MLX** for long generation | See [MLX Engines](benchmarks/mlx-engines.md) |

**Install in 60 seconds:**

```bash
curl -fsSL https://ollama.com/install.sh | sh   # Install Ollama
ollama pull gemma4:26b-nvfp4                      # Pull the best all-around model
ollama run gemma4:26b-nvfp4                        # Start chatting
```

---

<div class="grid cards" markdown>

-   ⚡ **Benchmarks**

    ---

    Real-world token-generation speeds for dozens of models. Compare
    quantization levels, MLX engines, and hardware configurations.

    [View Benchmarks →](benchmarks/index.md)

-   🚀 **Getting Started**

    ---

    From zero to inference in five minutes. Install Ollama, pull a model,
    and start generating.

    [Get Started →](getting-started.md)

-   📖 **Setup Guides**

    ---

    Step-by-step instructions for Ollama, MLX, Open WebUI,
    and memory management.

    [Browse Guides →](guides/ollama-setup.md)

-   🔧 **Workarounds**

    ---

    Documented fixes for known issues: the `/no_think` bug, context-length
    footguns, thinking-model quirks, and flash attention tuning.

    [See Workarounds →](workarounds/no-think-bug.md)

-   🏗️ **Architecture Patterns**

    ---

    Design systems that burst inference on local hardware and manage
    memory efficiently.

    [Explore Patterns →](architecture/burst-unload.md)

-   📚 **References**

    ---

    Official project sites, research papers, model publishers, and
    quantization references.

    [Full References →](references.md)

</div>

---

## Hardware Note

> **Tested on:** MacBook Pro M1 Max (64 GB). See the [Methodology page](benchmarks/methodology.md) for full hardware specs and measurement approach. Results scale to other M-series chips by memory bandwidth and GPU core count. I'll keep this guide updated as new models and quantizations become available.

---

## What's Inside

### 📊 Benchmarks

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

### 🔧 Setup Guides

- **Ollama** — Install, configure, pull models, serve, and integrate.
- **MLX** — Apple's machine learning framework for Apple Silicon.
- **Open WebUI** — A ChatGPT-like interface for local models.

- **Model selection** — How to choose the right model for your hardware and
  use case.
- **Memory management** — Tuning KV cache, context length, and concurrent
  model loading.

### 🐛 Workarounds

- **`/no_think` bug** — Fix for models that get stuck in thinking mode.
- **Context length footgun** — Why your model slows down and how to fix it.
- **Thinking models** — Running DeepSeek R1, QwQ, and other reasoning models.
- **Flash attention** — Enabling and tuning flash attention on Apple Silicon.
- **Speculative decoding** — Speed up inference with draft models.

### 🏗️ Architecture Patterns


- **Burst & Unload** — Load a model, run inference, unload — for batch
  processing and serverless-style workloads.
- **Serving comparison** — Ollama vs. MLX vs. llama.cpp on Apple Silicon.

---

## Test Hardware

All benchmarks and instructions in this guide were tested on this exact machine. See the [Benchmark Methodology](benchmarks/methodology.md) page for the complete hardware configuration, software versions, and measurement approach.

> **Compatibility:** Results scale to other M-series chips by memory bandwidth and GPU core count. M2/M3/M4 chips with equivalent or better specs will match or exceed these numbers. I'll update this guide as new models and quantizations land — verify on your system if you're on a different macOS version.

---

## Community

This guide is maintained by the community at
[r/LocalLLaMA](https://reddit.com/r/LocalLLaMA). Contributions, corrections,
and new benchmark data are always welcome.

- **GitHub**: [apple-silicon-llm-guide](https://github.com/apple-silicon-llm-guide/apple-silicon-llm-guide)
- **Reddit**: [r/LocalLLaMA](https://reddit.com/r/LocalLLaMA)
- **License**: MIT — free to use, share, and contribute to.