# Open WebUI Setup Guide

[Open WebUI](https://github.com/open-webui/open-webui) is a self-hosted web interface for LLMs. It connects to Ollama and MLX servers, providing a ChatGPT-like experience for your local models.

> **Basic installation, starting the server, and UI usage are covered by the Open WebUI docs.**
> This page only covers what is **different or specific to Apple silicon**.

- **Installation**: See the [Open WebUI README](https://github.com/open-webui/open-webui) for `pip install open-webui` or Docker install.
- **Starting the server**: `open-webui serve --port 8080` — see the README for options.
- **UI usage**: Open `http://localhost:8080` — the README covers model selection, chat, and settings.

## Connecting to Ollama

Open WebUI auto-detects Ollama running at `http://localhost:11434`. No configuration needed — models appear in the UI automatically.

### Manual Configuration

If Ollama is on a different host:

1. Go to **Settings → Connections**
2. Under **Ollama Base URL**, enter `http://your-ollama-host:11434`
3. Click **Save**

## Connecting to MLX / Rapid-MLX

MLX servers expose an OpenAI-compatible API, so Open WebUI connects to them as an OpenAI endpoint.

### Add an OpenAI Connection

1. Go to **Settings → Connections**
2. Click **Add Connection** under OpenAI API
3. Configure:

| Field | mlx_lm.server | Rapid-MLX | oMLX |
|---|---|---|---|
| **URL** | `http://localhost:8000/v1` | `http://localhost:8083/v1` | `http://localhost:8084/v1` |
| **API Key** | (leave blank) | (leave blank) | (leave blank) |
| **Prefix** | `mlx-` | `rapid-` | `omlx-` |

The prefix helps distinguish models from different providers in the model selector.

## Tool calling configuration (MLX-specific patches)

Open WebUI supports tool calling (function calling) with compatible models. MLX/Rapid-MLX servers require several patches to work correctly.

### 1. Float Timestamps

MLX servers return float timestamps in SSE chunks. Open WebUI expects integer timestamps:

```python
# In open-webui's backend, patch the SSE parser
# File: open_webui/utils/chat.py (approximate location)
def parse_sse_line(line):
    if line.startswith("data: "):
        data = json.loads(line[6:])
        # Handle float timestamps
        if "created" in data and isinstance(data["created"], float):
            data["created"] = int(data["created"])
        return data
```

### 2. Empty Content Fix

Some MLX servers return empty content in tool call responses:

```python
# Handle empty content in tool call responses
if "content" in choice["delta"] and choice["delta"]["content"] is None:
    choice["delta"]["content"] = ""
```

### 3. Socket.IO Transport

Open WebUI uses Socket.IO for real-time communication. Ensure your MLX server supports the correct transport:

```bash
# Start Rapid-MLX with WebSocket support
rapid-mlx serve ~/mlx-models/gemma4-9b-4bit --port 8083 --websocket
```

### 4. Auto Tool IDs

MLX servers do not generate unique tool call IDs:

```python
# Auto-generate tool call IDs if missing
if "tool_calls" in choice["delta"]:
    for tc in choice["delta"]["tool_calls"]:
        if "id" not in tc or not tc["id"]:
            tc["id"] = f"call_{uuid4().hex[:12]}"
```

### 5. API Keys

While MLX servers do not require API keys, Open WebUI enforces one. Set a dummy key:

```bash
# In Open WebUI settings, set API key to "not-needed" or "«redacted:sk-…»"
```

### 6. Chat Template

MLX models need a specific chat template. Configure in Open WebUI:

1. Go to **Settings → Models**
2. Select the model
3. Under **Chat Template**, paste the model's expected template format

Example for Gemma 4:

```text
<start_of_turn>user
{{prompt}}
<end_of_turn>
<start_of_turn>model
```

## Next steps

- [Ollama Setup](ollama-setup.md) — Setting up the Ollama backend
- [MLX Setup](mlx-setup.md) — Setting up MLX backends
- [Model Selection](model-selection.md) — Choosing the right models
