# Swap Impact: The Hidden 30% Performance Tax

> **TL;DR:** Stale swap from previous model runs costs 28–31% tok/s on small models — even when you have 40 GB of free RAM. macOS doesn't reclaim swap after models unload. The permanent fix: install **swap-guard** (a launchd agent that monitors swap and auto-purges). For one-off use: `sudo purge` before benchmarking, or `asimon clean --stop-ollama`.

## The Problem

macOS swaps aggressively under memory pressure. When you load a model that pushes past available RAM, the system pages memory to disk. But here's the trap: **macOS does not reclaim swap after the model unloads**. That stale swap sits there, contaminating future inference sessions.

LLM inference reads model weights sequentially from unified memory. When swap forces those reads to hit the SSD instead of RAM, throughput collapses. The model isn't running out of memory — it's running out of *fast* memory.

!!! warning "Swap ≠ Out-of-Memory"
    You can have 40 GB of free RAM and still lose 30% tok/s if 2.5 GB of stale swap sits between the model and clean memory. Swap is a performance tax, not a capacity indicator.

## My Evidence

Tested on **M1 Max 64 GB** (August 2026) with controlled clean vs. dirty baselines:

| Model | Size | Clean Baseline | Dirty Baseline | Improvement |
|-------|------|---------------|---------------|-------------|
| `hermes3:8b` | ~4.9 GB | 39.6 tok/s | 30.1 tok/s | **+31%** |
| `gemma4:12b-nvfp4` | ~7.2 GB | 24.5 tok/s | 19.2 tok/s | **+28%** |
| `gemma4:26b-mlx` | ~15.6 GB | 41.4 tok/s | 39.7 tok/s | **+4%** |

**Clean baseline:** 47 GB available, 553 MB swap, `purge` between models.  
**Dirty baseline:** 27 GB available, 2.5 GB swap, stale swap from prior runs, no purge.

The pattern is clear: small models lose 28–31% throughput. Large models that fill most of RAM anyway are less affected — they're already fighting for every byte.

## Why It Happens

Apple Silicon's unified memory architecture means the CPU, GPU, and Neural Engine all share the same physical RAM. When a model loads, its weights occupy a contiguous block of this shared memory. When the model unloads, the memory is freed — but macOS's VM subsystem may have already paged some of those pages to disk during the model's lifetime, and **it doesn't proactively page them back in**.

The result: even after the model is gone, swap usage stays elevated. When you load the next model, some of its memory reads hit the swap file instead of RAM. The SSD (even a fast one) is 10–50× slower than unified memory for the random-access patterns LLM inference generates.

## The Swap Tax Table

| Model Size | Swap Impact | Why |
|-----------|-------------|-----|
| < 10 GB | 28–31% loss | Most affected — RAM freed is contaminated by stale swap |
| 10–20 GB | 4–18% loss | Partial — some swap pages are useful, some are noise |
| > 20 GB | < 5% loss | Fills RAM anyway, swap is largely unavoidable |

Small models are hit hardest because they have the most to gain from clean memory. A 4.9 GB model like `hermes3:8b` fits easily in 64 GB of RAM — but if 2.5 GB of that RAM is backed by stale swap pages, the model's sequential weight reads hit the disk 30% of the time.

## How to Detect Swap Impact

### Quick Check

```bash
sysctl vm.swapusage
```

Look for `total = X.XX GB`. If it's above 1 GB and you haven't intentionally loaded a large model, you have stale swap.

### System Memory Pressure

```bash
memory_pressure
```

If you see `Pressure: 30%+` or `State: WK` (wakeup), the system is actively managing memory pressure — swap is likely involved.

### One-Shot Overview with macmon

```bash
macmon --once
```

Shows CPU/GPU power, thermal pressure, memory pressure, and swap usage in a single view. No sudo needed.

### Per-Process RSS

```bash
ps aux | grep ollama | awk '{print $6}'
```

Shows the RSS (resident set size) of Ollama processes. If RSS is significantly smaller than the model size, parts of the model are swapped out.

## Solutions (Ranked)

### 1. swap-guard (Automated Watchdog) — Recommended

The permanent fix. A launchd agent that monitors swap every 60 seconds and auto-purges when stale swap exceeds 1 GB. No manual intervention needed — install once and forget about it.

See the [Automated Solution: swap-guard](#automated-solution-swap-guard) section below for full install instructions.

### 2. Purge Swap Before Benchmarking

The most effective one-off fix. Clears the system's file cache and forces swap pages to be reclaimed:

```bash
# Stop any running models first
ollama stop hermes3:8b

# Purge the system cache (requires sudo)
sudo purge
```

Or use the `asimon` pipeline if you have it installed:

```bash
asimon clean --stop-ollama
```

This stops all Ollama models, purges the system cache, and gives you a clean baseline.

!!! tip "Do this before every benchmark session"
    A single `sudo purge` before your test run eliminates the 30% swap tax. It takes 2 seconds and costs nothing.

### 3. Reduce Model Footprint

Smaller models are less likely to trigger swap in the first place. Quantization is your best tool:

- **NVFP4** (MLX) — Best quality-to-size ratio, fastest cold start
- **Q4_K_M** (Ollama/GGUF) — Default 4-bit quant, good balance
- **Q8_0** — Higher quality, larger footprint
- **F16** — Full precision, largest footprint

See the [Quantization Guide](../benchmarks/quantization.md) for detailed comparisons.

### 4. Close Competing Apps

Browsers and IDEs are memory hogs:

- Chrome with 20+ tabs: 2–4 GB
- VS Code with extensions: 1–2 GB
- Slack/Discord/Teams: 0.5–1 GB each

Before a benchmark session, close everything except your terminal. Every GB you free reduces swap pressure.

### 5. Use KEEP_ALIVE=0s

Models stay in memory for 5 minutes by default after their last use. During that time, macOS may page parts of them to disk. Set `KEEP_ALIVE=0s` to unload immediately:

```bash
export OLLAMA_KEEP_ALIVE=0s
```

See the [Memory Management Guide](../guides/memory-management.md#keep_alive0s-for-burst-and-unload) for details.

### 6. Reduce Context Length

Longer context means larger KV cache, which means more memory pressure. If you don't need 128K context, don't use it:

```bash
# For a quick benchmark, use a short context
ollama run hermes3:8b --ctx-size 4096
```

See the [Context Length Footgun](context-length.md) page for the full story on how context length affects memory.

### 7. Monitor Continuously

Keep an eye on swap during long inference sessions:

```bash
# Every 5 seconds
watch -n5 'sysctl vm.swapusage'
```

Or use macmon in live mode for a richer view:

```bash
macmon
```

## Automated Solution: swap-guard

!!! tip "The Permanent Fix"
    Install once, forget about it. swap-guard monitors swap every 60 seconds and auto-purges when stale swap exceeds 1 GB. No manual `sudo purge` needed.

### The Problem with Manual Purge

`sudo purge` works — but you have to remember to run it. If you load a model, do some work, load another model later, the stale swap from the first session is still there. You lose 30% tok/s and don't even notice because the system isn't crashing — it's just slow.

swap-guard solves this by running as a **launchd agent** that checks swap every 60 seconds and purges automatically when stale swap exceeds a threshold.

### How It Works

1. Every 60 seconds, swap-guard reads `sysctl vm.swapusage` to check current swap usage
2. If swap is below 1 GB: no action (normal operation)
3. If swap exceeds 1 GB and no Ollama model is actively generating: runs `sudo purge`
4. If swap exceeds 4 GB: also stops idle Ollama models before purging (aggressive mode)
5. If an Ollama model IS generating: skips the purge (never interrupts active inference)
6. Logs every action to `/tmp/swap-guard.log` and sends a macOS notification

### Quick Install

```bash
# From the repo
cd scripts/
chmod +x install-swap-guard.sh
./install-swap-guard.sh
```

The installer:
- Copies `swap-guard.sh` to `/usr/local/bin/swap-guard`
- Creates a sudoers NOPASSWD entry for `/usr/sbin/purge` only
- Installs the launchd plist to `~/Library/LaunchAgents/`
- Loads the agent via `launchctl load`

### Check Status

```bash
# Is the agent running?
launchctl list | grep swap-guard

# View the log
tail -f /tmp/swap-guard.log

# View launchd stdout/stderr
tail -f /tmp/swap-guard-stdout.log
```

### Uninstall

```bash
./install-swap-guard.sh --uninstall
```

This removes the launchd agent, the script, the sudoers entry, and the log files. Ollama and other applications are unaffected.

### Source

The scripts live in the repo at `scripts/`:

- [`swap-guard.sh`](https://github.com/j3n0v4/apple-silicon-llm-guide/blob/main/scripts/swap-guard.sh) — The watchdog script
- [`com.vltx.swap-guard.plist`](https://github.com/j3n0v4/apple-silicon-llm-guide/blob/main/scripts/com.vltx.swap-guard.plist) — The launchd plist
- [`install-swap-guard.sh`](https://github.com/j3n0v4/apple-silicon-llm-guide/blob/main/scripts/install-swap-guard.sh) — The installer

## Key Insight

**Swap is not the same as out-of-memory.** You can have 40 GB of free RAM and still lose 30% tok/s if 2.5 GB of stale swap sits between the model and clean memory. The system isn't crashing — it's just silently paying a performance tax on every weight read.

The fix is trivial: `sudo purge` before your session. Don't let stale swap from yesterday's model run ruin today's benchmarks.

## Test Hardware

All measurements on **M1 Max, 64 GB RAM, macOS 26.6**. Results scale to other M-series chips proportionally by memory bandwidth. See the [Benchmark Methodology](../benchmarks/methodology.md) for the complete hardware configuration.

## Related Pages

- [Memory Management Guide](../guides/memory-management.md) — Unified memory, KV cache, KEEP_ALIVE
- [Quantization Guide](../benchmarks/quantization.md) — Reduce model footprint with quantization
- [Context Length Footgun](context-length.md) — Why context length affects memory pressure
- [Co-Residence Guide](../benchmarks/co-residence.md) — Running multiple models on limited RAM
