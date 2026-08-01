# Tool Calling Compatibility

Function calling (tool calling) is a core requirement for agentic workflows. This page documents which models support tool calling on Apple Silicon and to what extent.

## Compatibility Matrix

| Model | Single Tool Call | Parallel Tool Calls | `tool_choice:required` | Notes |
|-------|:----------------:|:-------------------:|:---------------------:|-------|
| qwen3-coder:30b | ✅ | ✅ | ✅ | Best overall tool calling |
| qwen3.6:35b-a3b-nvfp4 | ✅ | ✅ | ✅ | Strong MoE tool calling |
| qwen3.6:35b-a3b-coding-nvfp4 | ✅ | ✅ | ✅ | Coding-tuned MoE |
| gemma4:26b-nvfp4 | ✅ | ✅ | ✅ | Excellent tool calling |
| gemma4:e4b-nvfp4 | ✅ | ✅ | ✅ | Good tool calling |
| gemma4:e2b-nvfp4 | ✅ | ✅ | ✅ | Fast tool calling |
| gemma4:12b-nvfp4 | ✅ | ✅ | ✅ | Capable tool calling |
| deepseek-r1:14b | ✅ | ❌ | ❌ | Single tool only, no parallel |

## Detailed Results

### Single Tool Call

All tested models can handle a single tool call reliably. This is the simplest case — the model receives a function definition and a user query, and returns a structured function call.

**Test prompt:** "What's the weather in Tokyo?" with a `get_weather` function defined.

| Model | Success Rate | Response Time |
|-------|:-----------:|:-------------:|
| qwen3-coder:30b | 100% | ~1.2s |
| qwen3.6:35b-a3b-nvfp4 | 100% | ~1.5s |
| gemma4:26b-nvfp4 | 100% | ~1.3s |
| gemma4:e4b-nvfp4 | 100% | ~1.0s |
| deepseek-r1:14b | 100% | ~2.5s |

### Parallel Tool Calls

Parallel tool calling allows the model to call multiple functions in a single response — useful for gathering multiple data points simultaneously.

**Test prompt:** "What's the weather in Tokyo, London, and New York?" with a `get_weather` function.

| Model | Parallel Support | Max Parallel Calls | Reliability |
|-------|:---------------:|:------------------:|:-----------:|
| qwen3-coder:30b | ✅ | 5+ | Excellent |
| qwen3.6:35b-a3b-nvfp4 | ✅ | 5+ | Excellent |
| gemma4:26b-nvfp4 | ✅ | 5+ | Excellent |
| gemma4:e4b-nvfp4 | ✅ | 3-5 | Good |
| gemma4:e2b-nvfp4 | ✅ | 3 | Good |
| deepseek-r1:14b | ❌ | 0 | N/A — returns single call only |

### `tool_choice:required`

This parameter forces the model to always return a tool call, even if it would prefer to answer directly. You need this for agent loops where every response must be routed through a function.

| Model | Support | Behavior |
|-------|:-------:|----------|
| qwen3-coder:30b | ✅ | Reliable — always returns a tool call |
| qwen3.6:35b-a3b-nvfp4 | ✅ | Reliable |
| gemma4:26b-nvfp4 | ✅ | Reliable |
| gemma4:e4b-nvfp4 | ✅ | Reliable |
| gemma4:e2b-nvfp4 | ✅ | Reliable |
| deepseek-r1:14b | ❌ | May return text instead of tool call |

## DeepSeek R1 Limitations

DeepSeek R1 14B has significant tool calling limitations due to its thinking/reasoning architecture:

1. **No parallel tool calls** — it processes one function at a time
2. **No `tool_choice:required`** — it ignores the instruction and responds with text
3. **Thinking tokens interfere** — the chain-of-thought reasoning produces malformed tool call JSON
4. **Slower response** — the thinking process adds ~1-3s before the tool call is generated

**Workaround:** Use DeepSeek R1 for reasoning tasks only, and route tool calling to a different model (e.g., gemma4:e4b-nvfp4) in a multi-model setup.

## Tool Calling by Use Case

### Simple Function Calls

```json
{
  "name": "get_weather",
  "description": "Get current weather for a city",
  "parameters": {
    "type": "object",
    "properties": {
      "location": {"type": "string"}
    },
    "required": ["location"]
  }
}
```

**Works with:** All models.

### Multi-Function Orchestration

```json
[
  {
    "name": "search_docs",
    "description": "Search documentation",
    "parameters": {
      "type": "object",
      "properties": {
        "query": {"type": "string"}
      },
      "required": ["query"]
    }
  },
  {
    "name": "read_file",
    "description": "Read a file",
    "parameters": {
      "type": "object",
      "properties": {
        "path": {"type": "string"}
      },
      "required": ["path"]
    }
  }
]
```

**Works with:** All models except DeepSeek R1 (parallel not supported).

### Agent Loop (Forced Tool Call)

```python
response = client.chat.completions.create(
    model="qwen3-coder:30b",
    messages=[...],
    tools=[...],
    tool_choice="required"  # Force tool call every turn
)
```

**Works with:** All models except DeepSeek R1.

## Recommendations

| Use Case | Recommended Model | Why |
|----------|-----------------|-----|
| **General tool calling** | gemma4:e4b-nvfp4 | Fast, reliable, supports all modes |
| **Complex agent loops** | qwen3-coder:30b | Best parallel support, most reliable |
| **High-throughput tool calls** | gemma4:e2b-nvfp4 | 93.1 tok/s, supports all modes |
| **MoE tool calling** | qwen3.6:35b-a3b-nvfp4 | Good parallel support, memory efficient |
| **Reasoning + tools** | gemma4:26b-nvfp4 | Deep reasoning with full tool support |
| **Thinking-only** | deepseek-r1:14b | Use for reasoning, route tools elsewhere |

## Testing Your Model's Tool Calling

```python
import ollama

# Test single tool call
response = ollama.chat(
    model="gemma4:e4b-nvfp4",
    messages=[{"role": "user", "content": "What's the weather in Tokyo?"}],
    tools=[{
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get weather for a city",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {"type": "string"}
                },
                "required": ["location"]
            }
        }
    }]
)

print(response.message.tool_calls)
# Expected: [{'function': {'name': 'get_weather', 'arguments': {'location': 'Tokyo'}}}]
```

## Known Issues

1. **DeepSeek R1 malformed JSON:** The thinking tokens leak into the tool call JSON. Workaround: use a regex to extract the JSON from the response.
2. **Gemma 4 e2b parallel limit:** The smallest Gemma 4 variant drops parallel calls beyond 3. Use e4b or larger for reliable parallel calling.
3. **Qwen 3.6 MoE tool choice:** Very rarely, the MoE routing produces a text response instead of a tool call when `tool_choice:required` is set. Retry resolves it.
