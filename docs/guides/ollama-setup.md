# Ollama Setup Guide

Ollama is the most popular way to run LLMs locally on Apple silicon. It wraps llama.cpp with a clean CLI and an OpenAI-compatible REST API, using Metal GPU acceleration out of the box.

> **Basic installation, model pulling, API usage, and Modelfiles are covered by Ollama's own docs.**
> This page only covers what is **different or specific to Apple silicon**.

- **Installation**: See [ollama.com](https://ollama.com) for the macOS app or `brew install ollama`.
- **Pulling models**: See [ollama.com/library](https://ollama.com/library) for available models.
- **API reference**: See the [Ollama API docs](https://github.com/ollama/ollama?tab=readme-ov-file#api).
- **Modelfiles**: See the [Ollama Modelfile docs](https://github.com/ollama/ollama?tab=readme-ov-file#modelfile).

## Environment variables (Apple silicon performance tuning)

Ollama respects several environment variables that matter for Apple silicon performance:

```bash
# Prevent models from staying in memory after use
export OLLAMA_KEEP_ALIVE=0s

# Enable flash attention (reduces memory usage for long contexts)
export OLLAMA_FLASH_ATTENTION=1

# Use Q8_0 for KV cache (reduces memory without quality loss)
export OLLAMA_KV_CACHE_TYPE=q8_0

# Limit concurrent loaded models
export OLLAMA_MAX_LOADED_MODELS=2

# Limit parallel requests per model
export OLLAMA_NUM_PARALLEL=1
```

Set these in your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
echo 'export OLLAMA_KEEP_ALIVE=0s' >> ~/.zshrc
echo 'export OLLAMA_FLASH_ATTENTION=1' >> ~/.zshrc
echo 'export OLLAMA_KV_CACHE_TYPE=q8_0' >> ~/.zshrc
echo 'export OLLAMA_MAX_LOADED_MODELS=2' >> ~/.zshrc
echo 'export OLLAMA_NUM_PARALLEL=1' >> ~/.zshrc
source ~/.zshrc
```

### Environment Variable Reference

| Variable | Default | Recommended | Description |
|---|---|---|---|
| `OLLAMA_KEEP_ALIVE` | `5m` | `0s` | How long to keep a model loaded after last use. `0s` unloads immediately — important for burst-and-unload workflows. |
| `OLLAMA_FLASH_ATTENTION` | `0` | `1` | Enables flash attention, reducing memory usage for long context windows by ~30-50%. |
| `OLLAMA_KV_CACHE_TYPE` | `f16` | `q8_0` | KV cache quantization. `q8_0` halves memory without meaningful quality loss. |
| `OLLAMA_MAX_LOADED_MODELS` | `3` | `2` | Max models kept in memory simultaneously. Lower = more free RAM. |
| `OLLAMA_NUM_PARALLEL` | `1` | `1` | Parallel requests per model. >1 increases memory pressure. |
| `OLLAMA_HOST` | `localhost:11434` | — | Bind address. Change to `0.0.0.0:11434` for network access. |
| `OLLAMA_ORIGINS` | `*` | — | CORS origins for web apps. |
| `OLLAMA_DEBUG` | — | — | Enable debug logging. |

## Dual-stack architecture

Ollama on Apple silicon uses a **dual-stack** approach depending on the model format:

### GGUF → llama.cpp → Metal

Most Ollama models use the GGUF format, which runs through llama.cpp with Metal GPU acceleration. This path is mature, well-tested, and supports the widest range of models.

- **Pros**: Broad model support, mature codebase, good performance
- **Cons**: Limited to GGUF format models
- **GPU**: Metal Performance Shaders (MPS) backend

### Safetensors/NVFP4 → MLX Engine

Newer models (tagged `nvfp4`, `bf16`) use Apple's MLX framework directly. This path is optimized for Apple silicon unified memory architecture.

- **Pros**: Native Apple silicon optimization, supports Safetensors format
- **Cons**: Fewer models available, newer codebase
- **GPU**: Direct Metal compute via MLX

Ollama auto-detects the model format and selects the appropriate engine. No configuration needed — just pull the right tag.

## Troubleshooting (macOS-Specific)

### Model fails to load

```bash
# Check Ollama logs
ollama serve 2>&1 | grep -i error

# Verify model file integrity
ollama pull gemma4:e4b-nvfp4

# Check available memory
memory_pressure
```

### Slow inference

```bash
# Ensure flash attention is enabled
export OLLAMA_FLASH_ATTENTION=1

# Check if thermal throttling is active
pmset -g therm

# Monitor GPU usage
sudo powermetrics --samplers gpu_power -i 1000 -n 5
```

### API not responding

```bash
# Verify server is running
curl -s http://localhost:11434/api/tags | head -20

# Check port conflicts
lsof -i :11434

# Restart the service
killall ollama && ollama serve
```

### Out of memory errors

```bash
# Set keep-alive to 0s to unload immediately
export OLLAMA_KEEP_ALIVE=0s

# Reduce KV cache precision
export OLLAMA_KV_CACHE_TYPE=q8_0

# Use a smaller model or higher quantization
ollama pull gemma4:e2b-nvfp4
```

### Metal errors on startup

```bash
# Ensure you're on macOS 14+ (Sonoma or later)
sw_vers

# Reset Metal shader cache
rm -rf ~/Library/Application\ Support/Ollama/cache/
```

## Next steps

- [MLX Setup](mlx-setup.md) — Running models via Apple's MLX framework
- [Open WebUI](open-webui.md) — A web interface for your local models
- [Memory Management](memory-management.md) — Understanding unified memory and KV cache
- [Model Selection](model-selection.md) — Choosing the right model for your hardware
