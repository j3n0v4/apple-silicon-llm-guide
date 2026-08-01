# The `context_length` Footgun

## The Problem

Setting `model.context_length` globally in your Ollama config (`config.yaml`) is a trap. It applies to **every model** you load — silently clipping their context windows.

```yaml
# config.yaml — DO NOT DO THIS
model:
  context_length: 8192  # This clips ALL models!
```

If you set this to 8192 and then use a model with a 128K context window, you've just cut its effective context by 93%. The model will truncate inputs beyond 8192 tokens without warning.

## The Fix: Per-Model Override

Use `custom_providers` to set context length per-model instead:

```yaml
# config.yaml — CORRECT approach
model:
  # No global context_length — let each model use its native window

custom_providers:
  - name: local-llm
    url: http://localhost:11434/v1
    api_key: ollama
    models:
      - name: gemma4:26b-nvfp4
        context_length: 262144
      - name: gemma4:e4b-nvfp4
        context_length: 131072
      - name: qwen3-coder:30b
        context_length: 262144
      - name: deepseek-r1:14b
        context_length: 131072
```

## Checking Current Context Length

Use `ollama show` to see a model's configured context window:

```bash
ollama show gemma4:26b-nvfp4
```

Look for the `context length` field in the output. If it's lower than expected, check your config for a global `context_length` setting.

## Model Context Windows

| Model | Native Context | Notes |
|-------|---------------|-------|
| `gemma4:26b-nvfp4` | 262,144 tokens | Full 256K + overhead |
| `gemma4:e4b-nvfp4` | 131,072 tokens | Smaller variant, half the context |
| `qwen3-coder:30b` | 262,144 tokens | Code-optimized, full context |
| `deepseek-r1:14b` | 131,072 tokens | Reasoning model, moderate context |
| `qwen3.6:35b-a3b-nvfp4` | 131,072 tokens | General purpose |
| `llama3.3:70b` | 131,072 tokens | Large general model |

## KV Cache Memory Impact

Context length directly determines VRAM consumption through the KV cache. On Apple Silicon with unified memory, this matters:

| Context Length | Approx KV Cache (7B model) | Approx KV Cache (30B model) |
|---------------|---------------------------|----------------------------|
| 8,192 | ~1 GB | ~4 GB |
| 32,768 | ~4 GB | ~16 GB |
| 131,072 | ~16 GB | ~64 GB |
| 262,144 | ~32 GB | ~128 GB |

**M1 Max 64GB practical limits:**
- 7B models: up to ~131K context comfortably
- 30B models: up to ~32K context before memory pressure
- 70B models: 8K-16K context max

## How to Diagnose a Clipped Context

If your model seems to "forget" earlier parts of a long conversation:

```bash
# 1. Check the model's actual context length
ollama show gemma4:26b-nvfp4 | grep "context"

# 2. Check if a global context_length is set
cat ~/.ollama/config.yaml | grep -A2 "context_length"

# 3. Monitor memory usage during inference
# In another terminal:
while true; do
  memory_pressure | head -5
  sleep 2
done
```

## Best Practices

1. **Never set `model.context_length` globally** — always use per-model overrides
2. **Match context to your use case** — don't set 262K for a simple chat bot; you'll waste memory
3. **Monitor memory pressure** — if you see yellow/red pressure, reduce context length
4. **Consider the model size** — a 70B model at 131K context needs ~64GB just for KV cache
5. **Restart Ollama after config changes** — `launchctl kickstart gui/$(id -u)/ollama` or restart the app
