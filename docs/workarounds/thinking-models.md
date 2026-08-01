# Thinking Models: `reasoning_effort` Configuration Guide

## Overview

Modern LLMs with chain-of-thought reasoning (Gemma4, Qwen3.6, DeepSeek-R1) expose a `reasoning_effort` parameter that controls how much thinking the model does before answering. Get this wrong and your API returns empty responses.

## The Short Version

| Model | `reasoning_effort` Value | Notes |
|-------|-------------------------|-------|
| `gemma4:26b-nvfp4` | `none` | Works correctly |
| `gemma4:e4b-nvfp4` | `none` | Works correctly |
| `qwen3-coder:30b` | `none` | Works correctly |
| `qwen3.6:35b-a3b-nvfp4` | `none` | Works correctly |
| `deepseek-r1:14b` | `low` | **REQUIRED** — `none` produces empty content |
| `deepseek-r1:32b` | `low` | Same as 14b variant |
| `deepseek-r1:70b` | `low` | Same as 14b variant |

## DeepSeek-R1: The Special Case

DeepSeek-R1 is unique among thinking models. It **requires** `reasoning_effort=low` — setting it to `none` produces empty content, just like the `/no_think` bug.

```bash
# CORRECT for DeepSeek-R1
curl -X POST http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-r1:14b",
    "messages": [{"role": "user", "content": "What is the capital of France?"}],
    "reasoning_effort": "low"
  }'
```

```bash
# WRONG — produces empty content
curl -X POST http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-r1:14b",
    "messages": [{"role": "user", "content": "What is the capital of France?"}],
    "reasoning_effort": "none"
  }'
```

## MLX: No `reasoning_effort` Support

The MLX inference stack (`mlx_lm`, `oMLX`, `Rapid-MLX`) does **not** support the `reasoning_effort` parameter at all. If you're running models through MLX, you cannot suppress thinking output through the API.

```bash
# MLX — reasoning_effort is silently ignored
mlx_lm.generate \
  --model mlx-community/gemma-4-27b-it-4bit \
  --prompt "Hello" \
  --reasoning_effort none  # This flag does nothing in MLX
```

**Workaround for MLX:** To suppress thinking output with MLX:
1. Use a non-thinking model variant
2. Post-process the output to strip thinking blocks
3. Switch to Ollama for the API features

## Qwen3.6 Chat Template Bugs

Qwen3.6 has several known issues with its chat template that affect reliability:

### 1. `|items` Filter Crashes C++ Runtimes

The Qwen3.6 chat template uses a Jinja2 `|items` filter that is not supported by the minijinja C++ runtime used by llama.cpp and Ollama. This causes a template rendering crash:

```
Error: template error: filter 'items' not found
```

**Fix:** Use a patched chat template. The community-maintained fix replaces `|items` with a Jinja2-compatible alternative.

### 2. `|safe` Filter is Python-Only

The `|safe` Jinja2 filter is only available in Python's Jinja2 implementation. C++ runtimes (llama.cpp, Ollama) don't support it, causing template rendering failures.

### 3. Developer Role Missing

The default Qwen3.6 chat template does not include a `<|developer|>` role token, which means system prompts are not properly distinguished from user messages. This can cause the model to ignore system instructions.

### 4. Empty Thinking Blocks Waste Context

When thinking is suppressed, the template still generates empty `<think></think>` blocks that consume context tokens without adding value. Over long conversations, this can waste thousands of tokens.

### 5. `</thinking>` Hallucination

The model sometimes generates a closing `</thinking>` tag without an opening `<thinking>` tag, or generates multiple thinking blocks. This is a training artifact, not a template issue, but it interacts badly with parsers that expect well-formed thinking blocks.

## Fixed Chat Template

A community-maintained fixed chat template is available on HuggingFace that addresses all of these issues:

```bash
# Download the fixed template
wget https://huggingface.co/datasets/community/qwen3-fixed-template/resolve/main/chat_template.jinja

# Apply it to your local model
ollama create qwen3.6:35b-a3b-nvfp4-fixed -f - <<EOF
FROM qwen3.6:35b-a3b-nvfp4
TEMPLATE "$(cat chat_template.jinja)"
EOF
```

The fixed template:
- Replaces `|items` with a compatible alternative
- Removes `|safe` filter dependency
- Adds proper `<|developer|>` role support
- Suppresses empty thinking blocks when `reasoning_effort=none`
- Handles malformed thinking tag sequences

## Code Examples

### Python: Correct Usage for All Models

```python
import openai

client = openai.OpenAI(base_url="http://localhost:11434/v1", api_key="ollama")

def get_response(model: str, prompt: str, reasoning_effort: str = "none"):
    """Get a response with proper reasoning_effort handling."""
    
    # DeepSeek-R1 needs low instead of none
    if "deepseek" in model and reasoning_effort == "none":
        reasoning_effort = "low"
    
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        reasoning_effort=reasoning_effort
    )
    return response.choices[0].message.content

# Works for all models
print(get_response("gemma4:26b-nvfp4", "Hello"))
print(get_response("deepseek-r1:14b", "Hello"))  # Auto-adjusted to "low"
```

### Curl: Quick Test Script

```bash
#!/bin/bash
# test-reasoning.sh — Test reasoning_effort across models

MODELS=(
  "gemma4:26b-nvfp4:none"
  "gemma4:e4b-nvfp4:none"
  "qwen3-coder:30b:none"
  "deepseek-r1:14b:low"
)

for entry in "${MODELS[@]}"; do
  IFS=':' read -r model tag effort <<< "$entry"
  full_model="${model}:${tag}"
  
  echo "=== Testing $full_model (reasoning_effort=$effort) ==="
  
  content=$(curl -s http://localhost:11434/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"$full_model\",
      \"messages\": [{\"role\": \"user\", \"content\": \"Say exactly: OK\"}],
      \"reasoning_effort\": \"$effort\"
    }" | jq -r '.choices[0].message.content // "EMPTY"')
  
  if [ "$content" = "EMPTY" ] || [ -z "$content" ]; then
    echo "  ❌ FAIL: Empty content"
  else
    echo "  ✅ PASS: $content"
  fi
done
```

## Summary

- **Most thinking models**: use `reasoning_effort=none`
- **DeepSeek-R1**: use `reasoning_effort=low` (required)
- **MLX**: no `reasoning_effort` support — use Ollama for API features
- **Qwen3.6**: use the fixed chat template to avoid C++ runtime crashes
- **Verify** with a test prompt before relying on a model in production
