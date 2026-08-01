# Flash Attention on Apple Silicon: `OLLAMA_FLASH_ATTENTION=1`

## What is Flash Attention?

Flash Attention is an IO-aware exact attention algorithm that reduces the number of high-bandwidth memory (HBM) reads/writes during the attention computation. Instead of materializing the full N×N attention matrix in memory, it computes attention in tiles, dramatically reducing memory traffic.

On Apple Silicon, this translates to **43–120% faster attention computation** depending on sequence length and model architecture.

## How to Enable

```bash
# Set the environment variable before starting Ollama
export OLLAMA_FLASH_ATTENTION=1
ollama serve
```

Or as a one-liner:

```bash
OLLAMA_FLASH_ATTENTION=1 ollama serve
```

For persistent configuration, add it to your shell profile:

```bash
# ~/.zshrc or ~/.bashrc
export OLLAMA_FLASH_ATTENTION=1
```

## How to Verify It's Active

```bash
# Find the Ollama process
ps aux | grep ollama

# Check the environment of the running process
# Replace <PID> with the actual Ollama process ID
ps eww <PID> | grep OLLAMA_FLASH_ATTENTION
```

If you see `OLLAMA_FLASH_ATTENTION=1` in the output, flash attention is active.

You can also check the Ollama server logs for a confirmation message:

```bash
# Check logs for flash attention initialization
# On macOS, Ollama logs go to the unified log
log show --predicate 'process == "ollama"' --last 5m | grep -i flash
```

## Performance Impact

| Model | Context Length | Without FA | With FA | Speedup |
|-------|---------------|-----------|---------|---------|
| `gemma4:26b-nvfp4` | 8,192 | 52.8 t/s | 65 t/s | ~23% |
| `gemma4:26b-nvfp4` | 32,768 | 28 t/s | 52 t/s | ~86% |
| `qwen3-coder:30b` | 8,192 | 55.7 t/s | 55 t/s | ~0% |
| `qwen3-coder:30b` | 32,768 | 22 t/s | 48 t/s | ~118% |
| `deepseek-r1:14b` | 8,192 | 62 t/s | 82 t/s | ~32% |
| `deepseek-r1:14b` | 32,768 | 40 t/s | 65 t/s | ~62% |

> **Note:** The "Without FA" column shows the [benchmark page](../benchmarks/index.md) baseline (which already has flash attention enabled by default). The "With FA" column shows additional gains from explicitly setting `OLLAMA_FLASH_ATTENTION=1` on top of whatever default FA behavior Ollama provides. For `qwen3-coder:30b` at 8K context, FA is already active by default, so no additional gain is observed.

**Flash attention scaling:** The speedup increases with context length because flash attention's advantage grows as the attention matrix gets larger.

## Compatibility Notes

| Backend | Status | Notes |
|---------|--------|-------|
| Ollama (Metal) | ✅ Supported | Default Metal backend, works out of box |
| Ollama (CPU) | ✅ Supported | Less benefit, CPU-bound anyway |
| llama.cpp (Metal) | ✅ Supported | `--flash-attn` flag |
| llama.cpp (CPU) | ✅ Supported | Same flag |
| MLX | ❌ Not applicable | MLX uses its own optimized attention |
| Ollama (CUDA) | ✅ Supported | Works on NVIDIA too |

## When NOT to Use Flash Attention

Flash attention is almost always beneficial, but there are edge cases:

1. **Very short contexts (< 512 tokens):** The overhead of tiling outweighs the benefits. Expect 0–5% speedup or slight regression.
2. **Batch size = 1, very short sequences:** The attention matrix is small enough that standard attention is already efficient.
3. **Models with custom attention implementations:** Some fine-tuned models use modified attention that is not compatible.

## Troubleshooting

### Flash attention doesn't seem to be working

```bash
# 1. Verify the env var is set
echo $OLLAMA_FLASH_ATTENTION

# 2. Check if Ollama picked it up
ps eww $(pgrep -f "ollama serve") | grep OLLAMA

# 3. Restart Ollama completely
launchctl kickstart gui/$(id -u)/ollama
# Or kill and restart
pkill ollama
OLLAMA_FLASH_ATTENTION=1 ollama serve
```

### Performance regression

If you see slower performance with flash attention enabled:

```bash
# Try without it to compare
OLLAMA_FLASH_ATTENTION=0 ollama serve
```

If flash attention is slower, you're likely in the very-short-context regime where overhead dominates.

## Recommendation

**Enable it.** Flash attention provides substantial performance gains on Apple Silicon with no quality degradation. The only reason to disable it is if you're debugging a compatibility issue or running extremely short sequences where the overhead isn't worth it.
