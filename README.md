# Apple Silicon LLM Guide

> I bought a MacBook Pro M1 Max and wanted to find the best local LLM setup for the hardware. I benchmarked 9 models across 5 quantization formats on 64 GB unified memory. This guide shares what I found — benchmarks, workarounds, and recommendations that actually work on Apple Silicon.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![MkDocs](https://img.shields.io/badge/MkDocs-Material-009485.svg)](https://squidfunk.github.io/mkdocs-material/)
[![GitHub Pages](https://img.shields.io/badge/Hosted-GitHub%20Pages-222222.svg)](https://pages.github.com/)

**Browse the full guide at:**  \
[https://j3n0v4.github.io/apple-silicon-llm-guide/](https://j3n0v4.github.io/apple-silicon-llm-guide/)

---

## Quick Start

Install Ollama and run a model in under 2 minutes:

```bash
# Install Ollama
brew install ollama

# Start the server
ollama serve

# Pull and run the best all-round model for 64 GB
ollama pull gemma4:e4b-nvfp4
ollama run gemma4:e4b-nvfp4
```

That's it. You're running a local LLM on Apple Silicon.

Read the full guide at [j3n0v4.github.io/apple-silicon-llm-guide](https://j3n0v4.github.io/apple-silicon-llm-guide/) for benchmarks, MLX setup, workarounds, and quantization comparisons.

---

## TL;DR — Which Model Should You Use?

| Model | Best For | Throughput | Quality | RAM Budget |
|-------|----------|-----------|---------|------------|
| **gemma4:e2b-nvfp4** | Maximum speed — chat, summarization, high-throughput | **93.1 tok/s** | 9/10 | ~6.8 GB |
| **qwen3-coder:30b** | Best coding & tool calling | 55.7 tok/s | **10/10** | ~21 GB |
| **gemma4:e4b-nvfp4** | Best value — balanced general use | 60.4 tok/s | 8/10 | ~9.3 GB |
| **qwen3.6:35b-a3b-nvfp4** | Most efficient — MoE, 3B active params | 54.3 tok/s | 9/10 | ~22 GB |
| **deepseek-r1:14b** | Deep reasoning / chain-of-thought | 22.2 tok/s | **10/10** | ~49 GB |

**My pick for most people:** `gemma4:e4b-nvfp4` — 60 tok/s, 8/10 quality, fits in 9.3 GB. Pair it with `qwen3-coder:30b` for coding tasks and you've got a solid two-model setup for 64 GB.

---

## Benchmark Highlights

All numbers from a MacBook Pro M1 Max (64 GB) via Ollama's `/api/generate` endpoint.

| Metric | Model | Result |
|--------|-------|--------|
| **Fastest** | gemma4:e2b-nvfp4 | **93.1 tok/s** — nearly 2× faster than anything else |
| **Best quality** | qwen3-coder:30b | **10/10** quality at 55.7 tok/s — the coding king |
| **Best value** | gemma4:e4b-nvfp4 | **60.4 tok/s**, 8/10 quality, only 9.3 GB RAM |
| **Most efficient** | qwen3.6:35b-a3b-nvfp4 | **54.3 tok/s**, 9/10 quality — 35B params, only 3B active |

Full data with charts, cold-start times, and memory breakdowns on the [Benchmarks](docs/benchmarks/index.md) page.

---

## What This Guide Covers

I benchmarked 9 models across 5 quantization formats on M1 Max 64 GB. Here's what I found:

- **Benchmarks** — Token-generation speeds for dozens of model/quantization combos, with MLX engine comparisons and cold-start timing.
- **Setup Guides** — Apple Silicon-specific config for Ollama, MLX, Open WebUI, and more. No generic Linux instructions.
- **Architecture Patterns** — How to burst inference on local hardware and manage memory efficiently. Apple Silicon's unified memory is shared by CPU and GPU — great for bandwidth, but everything competes for the same pool.
- **Workarounds** — Real bugs I hit: the `/no_think` bug, context-length footguns, thinking-model quirks, flash attention tuning, and why speculative decoding isn't worth it on this hardware.
- **Quantization** — Practical guidance on GGUF, NVFP4, MXFP8, Q4_K_M, and other formats. Which ones actually matter on Apple Silicon.

---

## Test Hardware

All benchmarks and instructions were tested on:

| Spec | Value |
|------|-------|
| **Machine** | MacBook Pro (2021) |
| **SoC** | Apple M1 Max |
| **GPU** | 24-core |
| **Memory** | 64 GB unified memory (400 GB/s) |
| **OS** | macOS 26.6 (Tahoe) |

Results scale to other M-series chips by memory bandwidth and GPU core count. I'll keep this guide updated as new models and quantizations become available.

---

## Local Development

```bash
pip install -e ".[dev]"
mkdocs serve      # live-reload dev server
mkdocs build      # static site
mkdocs gh-deploy  # deploy to GitHub Pages
```

Or use the Makefile: `make install`, `make serve`, `make build`, `make deploy`.

---

## Contributing

Contributions are welcome — especially benchmark data from other Apple Silicon machines. If you're running on M2, M3, M4, or a machine with more than 64 GB, your numbers would help the community.

**How to contribute benchmarks:**

1. Run the benchmark script from `docs/benchmarks/methodology.md` on your machine
2. Add your results to the appropriate table in `docs/benchmarks/model-comparison.md`
3. Include your hardware specs (chip, RAM, GPU cores, macOS version)
4. Open a pull request

**Other contributions:** bug fixes, new workarounds, setup guides for configurations I haven't tested. Fork the repo, create a branch, run `mkdocs build --strict` to verify, and open a PR.
