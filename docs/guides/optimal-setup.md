# Optimal Setup Guide

> **Tested hardware:** MacBook Pro M1 Max (64 GB). This page ties together every recommendation from the guide into one benchmark-backed setup. If you have a different RAM tier, start with the [Model Selection Guide](model-selection.md) instead.

## TL;DR

Here's the complete optimal configuration for M1 Max 64 GB. Run the [setup script](#the-complete-setup-script) at the bottom of this page to do it all at once.

### Recommended Models

| Model | Pull Command | Speed | RAM Budget | Best For |
|-------|-------------|-------|-----------|----------|
| `gemma4:e4b-nvfp4` | `ollama pull gemma4:e4b-nvfp4` | 60 tok/s | ~9.3 GB | **Daily driver** — fast, small, pairs with anything |
| `qwen3-coder:30b` | `ollama pull qwen3-coder:30b` | 56 tok/s | ~21 GB | **Coding** — best tool calling, 10/10 quality |
| `deepseek-r1:14b` | `ollama pull deepseek-r1:14b` | 22 tok/s | ~49 GB | **Reasoning** — chain-of-thought, but watch the KV cache |
| `gemma4:e2b-nvfp4` | `ollama pull gemma4:e2b-nvfp4` | 93 tok/s | ~6.8 GB | **Maximum speed** — fastest model tested |
| `qwen3.6:35b-a3b-nvfp4` | `ollama pull qwen3.6:35b-a3b-nvfp4` | 54 tok/s | ~22 GB | **MoE efficiency** — 35B params, only 3B active |

### One-Time System Config

```bash
# Raise GPU memory limit (64 GB machines)
sudo sysctl iogpu.wired_limit_mb=57344

# Install swap-guard (auto-purges stale swap)
cd scripts/ && chmod +x install-swap-guard.sh && sudo ./install-swap-guard.sh

# Set KEEP_ALIVE=0s (unload models immediately)
export OLLAMA_KEEP_ALIVE=0s
```

---

## System Configuration

These are one-time changes. Do them once and forget about them.

### Raise the GPU Memory Limit

macOS caps GPU-addressable memory at ~48 GB by default on 64 GB machines. Raise it to **57344 MB** to give models access to the full pool:

```bash
sudo sysctl iogpu.wired_limit_mb=57344
```

Make it permanent by adding to `/etc/sysctl.conf`:

```bash
echo "iogpu.wired_limit_mb=57344" | sudo tee -a /etc/sysctl.conf
```

See the [Memory Management Guide](memory-management.md#raising-the-gpu-memory-limit) for safe limits by RAM tier and the warning about setting it too high.

### Install swap-guard

Stale swap from previous model runs costs **28–31% tok/s on small models** — even when you have 40 GB of free RAM. macOS doesn't reclaim swap after models unload. swap-guard is a launchd agent that monitors swap every 60 seconds and auto-purges when stale swap exceeds 1 GB.

```bash
cd scripts/
chmod +x install-swap-guard.sh
sudo ./install-swap-guard.sh
```

See the [Swap Impact page](../workarounds/swap-impact.md#automated-solution-swap-guard) for full install instructions, status checks, and uninstall.

### Set KEEP_ALIVE=0s

By default, Ollama keeps models loaded for 5 minutes after the last request. That's 9+ GB of memory sitting idle. `KEEP_ALIVE=0s` unloads the model immediately after the response is complete:

```bash
export OLLAMA_KEEP_ALIVE=0s
```

Add it to your shell profile (`~/.zshrc` or `~/.bashrc`) to make it permanent. See the [Memory Management Guide](memory-management.md#keep_alive0s-for-burst-and-unload) for the full breakdown of when to use it and when not to.

### App Memory Usage

Reference numbers for budgeting memory on 64 GB:

- Chrome (20+ tabs): 2–4 GB
- VS Code + extensions: 1–2 GB
- Slack/Discord/Teams: 0.5–1 GB each

Every GB freed reduces swap pressure. Close what you don't need before benchmarking.

---

## Model Selection

These are the five models I recommend for M1 Max 64 GB, ordered by use case. All data is from my [Model Comparison benchmarks](../benchmarks/model-comparison.md).

### Daily Driver: `gemma4:e4b-nvfp4`

**60.4 tok/s, ~9.3 GB budget, 2.0s cold start**

This is the model I use most. It's fast enough for interactive chat, small enough to pair with any other model, and has excellent quality (8/10). The NVFP4 quantization keeps the file size at 8.8 GB while maintaining good fidelity.

```bash
ollama pull gemma4:e4b-nvfp4
```

### Coding: `qwen3-coder:30b`

**55.7 tok/s, ~21 GB budget, 7.8s cold start**

The best coding model I've tested. 10/10 quality for code generation, best tool calling support of any model on Apple Silicon. The cold start is slow (7.8s), but once loaded it generates at 56 tok/s.

```bash
ollama pull qwen3-coder:30b
```

### Reasoning: `deepseek-r1:14b`

**22.2 tok/s, ~49 GB budget, 2.79s cold start**

10/10 quality for chain-of-thought reasoning, but there's a catch: the model itself is only 9 GB, but its KV cache at 128K context is **40 GB**. That brings the total to ~49 GB — nearly filling the machine. If you reduce context to 32K, the KV cache drops to 10 GB and the total falls to ~19 GB.

```bash
ollama pull deepseek-r1:14b
```

See the [Context Length Footgun](../workarounds/context-length.md) page for the full story on how context length affects memory.

### Maximum Speed: `gemma4:e2b-nvfp4`

**93.1 tok/s, ~6.8 GB budget, 1.51s cold start**

The fastest model I've tested. Tiny footprint, instant cold start. Great for high-throughput tasks, summarization, or when you just want a snappy chat experience. Quality is 9/10 — surprisingly good for its size.

```bash
ollama pull gemma4:e2b-nvfp4
```

### MoE Efficiency: `qwen3.6:35b-a3b-nvfp4`

**54.3 tok/s, ~22 GB budget, 5.0s cold start**

35 billion total parameters, but only **3 billion active** per token. This means it runs nearly as fast as a 3B model while delivering quality closer to a 35B model. The MoE architecture is the best quality-to-speed ratio on Apple Silicon.

```bash
ollama pull qwen3.6:35b-a3b-nvfp4
```

---

## Co-Residence Config

Running two models simultaneously lets you specialize: use a fast model for simple queries and a powerful model for complex reasoning.

### The Best Pair

**`gemma4:e4b-nvfp4` + `qwen3-coder:30b`**

| Model | Budget |
|-------|--------|
| gemma4:e4b-nvfp4 | ~9.3 GB |
| qwen3-coder:30b | ~21 GB |
| **Total** | **~30 GB** |
| **Headroom** | **25 GB** |

That's 30 GB for models, leaving 25 GB for macOS and other apps. This is the ultimate combo: fast general chat + excellent coding.

### What NOT to Pair

DeepSeek R1 14B is the pairing challenge. Its 40 GB KV cache at 128K context means it can't share memory with any other large model:

| Pair | Total | Why |
|------|-------|-----|
| deepseek-r1:14b + qwen3-coder:30b | ~70 GB | Exceeds 64 GB by 6 GB |
| deepseek-r1:14b + gemma4:26b-nvfp4 | ~68 GB | Exceeds 64 GB by 4 GB |
| deepseek-r1:14b + qwen3.6:35b-a3b-nvfp4 | ~71 GB | Exceeds 64 GB by 7 GB |

See the [Co-Residence Guide](../benchmarks/co-residence.md) for the full pairing table and context-length tradeoffs.

### KEEP_ALIVE for Burst-and-Unload

With `KEEP_ALIVE=0s`, each model is loaded on demand and unloaded immediately. This is the key to making multi-model setups work without manual management:

```bash
# Switch between models — each loads, runs, and unloads
ollama run gemma4:e4b-nvfp4 "Quick question" --keep-alive 0s
ollama run qwen3-coder:30b "Write a function" --keep-alive 0s
```

See the [Burst & Unload pattern](../architecture/burst-unload.md) for the full trade-off analysis.

---

## Serving Engine Choice

### Ollama for Daily Use

Ollama is my default. It's the simplest setup, has the best model management (`ollama pull` / `ollama run`), native tool calling, and built-in OpenAI-compatible API. It also supports `KEEP_ALIVE` for burst-and-unload and multi-model setups.

**Ollama 0.19+ uses MLX for safetensors models automatically** — so you get MLX-level performance without the Python setup.

### MLX (Rapid-MLX) for Max Throughput

If I need every last token per second on a single model, I switch to MLX. Rapid-MLX generates at **51.4 tok/s** on a 35B MoE model — 38% faster than mlx_lm. But it has a high prefill overhead (~28s for 2K tokens), so it's only worth it for long-form generation.

For interactive work, **oMLX** is the better MLX choice — its prefill is 5x faster than Rapid-MLX.

See the [MLX Engine Comparison](../benchmarks/mlx-engines.md) for the full head-to-head, and the [Serving Comparison](../architecture/serving-comparison.md) for when to use each engine.

---

## Context Length Tuning

Don't use 128K context unless you actually need it. Context length is the biggest hidden memory cost.

### Context Cost Table

| Context | KV Cache (9B) | KV Cache (26B) | KV Cache (30B coder) | KV Cache (R1 14B) |
|---------|---------------|---------------|---------------------|-------------------|
| 4,096 | 0.33 GB | 0.95 GB | 0.5 GB | 1.25 GB |
| 8,192 | 0.66 GB | 1.90 GB | 0.19 GB | 2.5 GB |
| 16,384 | 1.31 GB | 3.79 GB | 0.38 GB | 5 GB |
| 32,768 | 2.62 GB | 7.58 GB | 0.75 GB | 10 GB |
| 131,072 | 10.49 GB | 30.33 GB | 3.0 GB | 40 GB |

### Recommended Defaults

| Model | Recommended Context | Why |
|-------|-------------------|-----|
| `gemma4:e4b-nvfp4` | 8,192 | Fast chat doesn't need long context |
| `gemma4:e2b-nvfp4` | 4,096 | Speed-focused, short queries |
| `qwen3-coder:30b` | 32,768 | Code needs moderate context |
| `deepseek-r1:14b` | 8,192–32,768 | 128K costs 40 GB in KV cache alone |
| `qwen3.6:35b-a3b-nvfp4` | 16,384 | Good balance for MoE reasoning |

See the [Context Length Footgun](../workarounds/context-length.md) page for the full analysis, including how to set per-model context length in your config.

---

## Monitoring

Keep an eye on your system while running models. Here are the three commands I use most:

### macmon — Thermal + Memory Overview

```bash
# One-shot overview (no sudo needed)
macmon --once
```

Shows CPU/GPU power, thermal pressure, memory pressure, and fan speed. Install with `brew install macmon`. See the [Memory Management Guide](memory-management.md#using-macmon-recommended) for details.

### Swap Check

```bash
sysctl vm.swapusage
```

Look for `total = X.XX GB`. If it's above 1 GB and you haven't loaded a large model, you have stale swap. See the [Swap Impact page](../workarounds/swap-impact.md#quick-check) for the full story.

### System Memory Pressure

```bash
memory_pressure
```

If you see `Pressure: 30%+` or `State: WK` (wakeup), the system is actively managing memory pressure — swap is likely involved.

---

## The Complete Setup Script

Run this once on a fresh machine. It does everything: installs Ollama, configures the system, pulls the recommended models, and verifies everything works.

```bash
#!/bin/bash
# Apple Silicon LLM Guide — Optimal Setup Script
# M1 Max 64 GB target. Adjust GPU limit for other RAM sizes.

set -e

echo "=== Apple Silicon LLM — Optimal Setup ==="

# 1. Install Ollama (if not installed)
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama already installed ($(ollama --version))"
fi

# 2. Raise GPU memory limit (64 GB machines)
echo "Setting GPU memory limit to 57344 MB..."
sudo sysctl iogpu.wired_limit_mb=57344
if ! grep -q "iogpu.wired_limit_mb=57344" /etc/sysctl.conf 2>/dev/null; then
    echo "iogpu.wired_limit_mb=57344" | sudo tee -a /etc/sysctl.conf
    echo "Made permanent in /etc/sysctl.conf"
fi

# 3. Install swap-guard
if [ -f scripts/install-swap-guard.sh ]; then
    echo "Installing swap-guard..."
    chmod +x scripts/install-swap-guard.sh
    sudo ./scripts/install-swap-guard.sh
else
    echo "WARNING: scripts/install-swap-guard.sh not found. Skipping."
    echo "Clone the repo or download from:"
    echo "  https://github.com/j3n0v4/apple-silicon-llm-guide"
fi

# 4. Set KEEP_ALIVE=0s
echo "Setting OLLAMA_KEEP_ALIVE=0s..."
if ! grep -q "OLLAMA_KEEP_ALIVE=0s" ~/.zshrc 2>/dev/null; then
    echo 'export OLLAMA_KEEP_ALIVE=0s' >> ~/.zshrc
    echo "Added to ~/.zshrc"
fi
if ! grep -q "OLLAMA_KEEP_ALIVE=0s" ~/.bashrc 2>/dev/null; then
    echo 'export OLLAMA_KEEP_ALIVE=0s' >> ~/.bashrc
    echo "Added to ~/.bashrc"
fi
export OLLAMA_KEEP_ALIVE=0s

# 5. Pull recommended models
echo ""
echo "=== Pulling recommended models ==="
echo "(This will take a while depending on your internet speed)"

MODELS=(
    "gemma4:e4b-nvfp4"
    "qwen3-coder:30b"
    "deepseek-r1:14b"
    "gemma4:e2b-nvfp4"
    "qwen3.6:35b-a3b-nvfp4"
)

for model in "${MODELS[@]}"; do
    echo ""
    echo "--- Pulling $model ---"
    ollama pull "$model"
done

# 6. Verify everything works
echo ""
echo "=== Verification ==="

echo ""
echo "GPU memory limit:"
sysctl iogpu.wired_limit_mb

echo ""
echo "Swap status:"
sysctl vm.swapusage

echo ""
echo "swap-guard status:"
launchctl list | grep swap-guard || echo "swap-guard not running (check install)"

echo ""
echo "Pulled models:"
ollama list

echo ""
echo "Quick smoke test (gemma4:e4b-nvfp4):"
ollama run gemma4:e4b-nvfp4 --keep-alive 0s "Say 'Setup complete!' in exactly 3 words"

echo ""
echo "=== Setup complete! ==="
echo "Restart your terminal or run 'source ~/.zshrc' to apply KEEP_ALIVE=0s."
echo "See https://j3n0v4.github.io/apple-silicon-llm-guide/guides/optimal-setup/ for docs."
```

---

## What's Next

- [Model Selection Guide](model-selection.md) — Choose models for your RAM tier
- [Memory Management](memory-management.md) — Deep dive into unified memory and KV cache
- [Ollama Setup](ollama-setup.md) — Full Ollama configuration reference
- [MLX Setup](mlx-setup.md) — Set up MLX for native Apple Silicon performance
- [Open WebUI](open-webui.md) — Web interface for your models
