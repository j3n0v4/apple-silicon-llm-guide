# Getting Started

Run your first LLM on Apple silicon in under five minutes.

---

## 1. Install Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Ollama installs as a launchd service and auto-starts. Verify: `ollama --version`.

See the [Ollama Setup Guide](guides/ollama-setup.md) for environment variables, dual-stack architecture, and macOS troubleshooting.

## 2. Pull a Model

```bash
ollama pull gemma4:26b-nvfp4
```

| RAM | Recommended Model |
|-----|------------------|
| 16 GB | `llama3.1:8b` or `qwen3-coder:8b` |
| 32 GB | `gemma4:26b-nvfp4` or `qwen3-coder:8b` |
| 64 GB | `gemma4:26b-nvfp4`, `qwen3-coder:30b`, or `deepseek-r1:32b` |
| 128 GB+ | `deepseek-r1:70b` or `qwen3-coder:30b` |

See the [Model Selection guide](guides/model-selection.md) for detailed recommendations.

## 3. Test It

```bash
ollama run gemma4:26b-nvfp4 "What is the capital of France?"
```

For API usage, see the [Ollama API docs](https://github.com/ollama/ollama?tab=readme-ov-file#api).

## 4. Add Open WebUI (Optional)

```bash
pip install open-webui
open-webui serve
```

Open `http://localhost:8080` — your Ollama models appear automatically. See the [Open WebUI Guide](guides/open-webui.md) for MLX server integration and tool-calling patches.

## 5. Add MLX for Maximum Speed (Optional)

[MLX](https://github.com/ml-explore/mlx) is Apple's native ML framework — **~29% faster than Ollama** for single-batch inference on M1 Max.

```bash
pip install omlx
omlx serve --model mlx-community/gemma-4-26b-it-4bit --port 8000
```

| Engine | Best For | Install |
|--------|----------|---------|
| **oMLX** | Chat, agents, RAG — fastest prefill (5x faster than mlx_lm) | `pip install omlx` |
| **Rapid-MLX** | Long-form generation — fastest generation (38% faster than mlx_lm) | `pip install rapid-mlx` |
| **mlx_lm** | Stable fallback, most documented | `pip install mlx-lm` |

See the [MLX Setup Guide](guides/mlx-setup.md) for engine comparison, PYTHONPATH fix, and macOS troubleshooting.

## Verification checklist

- [ ] **Ollama is running**: `curl http://localhost:11434/api/tags` returns JSON
- [ ] **Model responds**: `ollama run gemma4:26b-nvfp4 "Hi"` generates text
- [ ] **Open WebUI loads**: `http://localhost:8080` shows the chat interface
- [ ] **Metal acceleration**: GPU utilization visible in Activity Monitor during inference

## Next steps

- **[Benchmarks](benchmarks/index.md)** — See how your hardware compares
- **[Ollama Setup Guide](guides/ollama-setup.md)** — Env vars, dual-stack, troubleshooting
- **[MLX Setup Guide](guides/mlx-setup.md)** — Engine comparison, PYTHONPATH fix
- **[Open WebUI Guide](guides/open-webui.md)** — MLX integration, tool-calling patches
- **[Workarounds](workarounds/no-think-bug.md)** — Fixes for common issues
