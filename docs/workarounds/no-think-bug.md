# The `/no_think` Bug: Empty Content on OpenAI-Compatible API

## The Problem

When using the `/no_think` suffix in model tags with Ollama's OpenAI-compatible API endpoint (`/v1/chat/completions`), the response contains **empty content** — the thinking block is suppressed, but so is the actual response text.

This bug directly inflated every v4 benchmark score. Models like Gemma4, Qwen3.6, and DeepSeek-R1 were tested with `/no_think` to suppress chain-of-thought output during evaluation. The assumption was that `/no_think` only strips the thinking trace. In reality, it also strips the content field, producing an empty response that benchmark harnesses interpreted as a zero-cost correct answer.

## Affected Models

All thinking models that support the `/no_think` suffix are affected:

| Model | Tag | Status |
|-------|-----|--------|
| Gemma4 | `gemma4:26b-nvfp4` | Broken with `/no_think` |
| Gemma4 | `gemma4:e4b-nvfp4` | Broken with `/no_think` |
| Qwen3.6 | `qwen3.6:35b-a3b-nvfp4` | Broken with `/no_think` |
| DeepSeek-R1 | `deepseek-r1:14b` | Broken with `/no_think` |

## The Fix: Use `reasoning_effort` Instead

The correct approach is to set `reasoning_effort` in the request body rather than using the `/no_think` model tag suffix.

### Broken Approach (DO NOT USE)

```bash
# This produces empty content — the model responds with nothing
curl -X POST http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:26b-nvfp4/no_think",
    "messages": [{"role": "user", "content": "What is 2+2?"}]
  }'
```

**Response (broken):**
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": ""
    }
  }]
}
```

### Working Approach (USE THIS)

```bash
# reasoning_effort=none suppresses thinking while keeping content intact
curl -X POST http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:26b-nvfp4",
    "messages": [{"role": "user", "content": "What is 2+2?"}],
    "reasoning_effort": "none"
  }'
```

**Response (working):**
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "2+2 equals 4."
    }
  }]
}
```

## DeepSeek-R1 Special Case

DeepSeek-R1 has an additional quirk: `reasoning_effort=none` also produces empty content. You must use `reasoning_effort=low` instead.

```bash
# DeepSeek-R1: use reasoning_effort=low, NOT none
curl -X POST http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-r1:14b",
    "messages": [{"role": "user", "content": "Explain recursion."}],
    "reasoning_effort": "low"
  }'
```

## Python SDK Example

```python
import openai

client = openai.OpenAI(base_url="http://localhost:11434/v1", api_key="ollama")

# BROKEN
response = client.chat.completions.create(
    model="gemma4:26b-nvfp4/no_think",
    messages=[{"role": "user", "content": "Hello"}]
)
print(response.choices[0].message.content)  # Empty string!

# WORKING
response = client.chat.completions.create(
    model="gemma4:26b-nvfp4",
    messages=[{"role": "user", "content": "Hello"}],
    reasoning_effort="none"
)
print(response.choices[0].message.content)  # Actual response
```

## Why This Happens

The `/no_think` suffix is a Ollama-specific model tag modifier that tells the inference engine to strip thinking tokens from the output. On the native Ollama API (`/api/generate` and `/api/chat`), this works correctly — thinking is removed, content is preserved. However, on the OpenAI-compatible endpoint (`/v1/chat/completions`), the implementation has a bug where suppressing the thinking block also suppresses the content generation entirely.

The `reasoning_effort` parameter, on the other hand, is part of the OpenAI API spec and is handled at the protocol layer rather than the model tag layer, so it correctly suppresses reasoning while preserving the final answer.

## Verification

To verify you're getting real content:

```bash
# Check that content is non-empty
curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:26b-nvfp4",
    "messages": [{"role": "user", "content": "Say exactly: hello world"}],
    "reasoning_effort": "none"
  }' | jq -r '.choices[0].message.content'
```

Expected output: `hello world`
