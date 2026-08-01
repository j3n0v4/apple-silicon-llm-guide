# MLX Setup Guide

[MLX](https://github.com/ml-explore/mlx) is Apple's machine learning framework for Apple Silicon. Unlike Ollama's dual-stack approach, MLX runs natively on Metal with no translation layer — it speaks directly to the GPU through Apple's Metal Performance Shaders.

> **Basic installation, model downloading, serving, and API usage are covered by the mlx-lm README.**
> This guide only covers what's **different or specific to Apple Silicon**.

- **Installation**: See the [mlx-lm README](https://github.com/ml-explore/mlx-lm) for `pip install mlx mlx-lm`.
- **Downloading models**: MLX models are on HuggingFace at [mlx-community](https://huggingface.co/mlx-community). Use `huggingface-cli download` or let `mlx_lm` auto-download.
- **Serving**: See the mlx-lm README for `python -m mlx_lm.server` usage.
- **OpenAI-compatible API**: All MLX servers expose `/v1/chat/completions` — see the mlx-lm README for curl and Python SDK examples.

## PYTHONPATH Contamination Fix

MLX servers can suffer from `PYTHONPATH` contamination — environment variables from your shell leaking into the server process and causing import conflicts or unexpected behavior.

### The Problem

```bash
# If PYTHONPATH includes conflicting packages, MLX:
# - Import wrong versions of dependencies
# - Fail to start with cryptic errors
# - Behave differently than expected
```

### The Fix: Clean Environment

```bash
# Use env -i to start with a clean environment
env -i PATH="$PATH" HOME="$HOME" rapid-mlx serve ~/mlx-models/gemma4-9b-4bit --port 8083

# Or as a launch script
cat > ~/mlx-serve.sh << 'EOF'
#!/bin/bash
exec env -i \
  PATH="$PATH" \
  HOME="$HOME" \
  USER="$USER" \
  rapid-mlx serve "$@" --port 8083
EOF
chmod +x ~/mlx-serve.sh
```

### Launchd Service (persistent)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.rapid-mlx</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/you/mlx-serve.sh</string>
        <string>/Users/you/mlx-models/gemma4-9b-4bit</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin</string>
    </dict>
</dict>
</plist>
```

## Performance Comparison Between Engines

| Engine | Startup Time | Throughput | Memory Usage | Tool Calling |
|--------|-------------|-----------|-------------|-------------|
| **mlx_lm.server** | Slow (loads full model) | Good | Moderate | Limited |
| **Rapid-MLX** | Fast (lazy loading) | Excellent | Low | Good |
| **oMLX** | Moderate | Good | Moderate | Best |

### Benchmark Results (Gemma 4 9B 4-bit, M1 Max 64 GB)

| Metric | mlx_lm.server | Rapid-MLX | oMLX |
|---|---|---|---|
| Time to first token | 3.2s | 0.8s | 1.5s |
| Tokens/second | 45.2 | 52.1 | 48.7 |
| Peak memory | 8.1 GB | 7.4 GB | 8.3 GB |
| Idle memory | 6.8 GB | 0.2 GB | 1.1 GB |

Rapid-MLX's lazy loading means it uses almost no memory when idle — ideal for burst-and-unload workflows.

## Troubleshooting (macOS-Specific)

### "No module named 'mlx'" after install

```bash
# Ensure you're in the right virtual environment
which python
python -c "import mlx; print(mlx.__version__)"

# Reinstall if needed
pip uninstall mlx mlx-lm
pip install mlx mlx-lm --no-cache-dir
```

### Metal device not found

```bash
# Verify Apple Silicon
sysctl -n machdep.cpu.brand_string

# Check Metal support
system_profiler SPDisplaysDataType | grep Metal

# Ensure macOS 14+
sw_vers
```

### Server starts but returns 404

```bash
# Check the correct endpoint path
curl http://localhost:8000/v1/models

# mlx_lm.server uses /v1/chat/completions
# Rapid-MLX uses /v1/chat/completions
# oMLX uses /v1/chat/completions
```

### Out of memory during inference

```bash
# Use a smaller model
# Reduce max-kv-size / max-tokens
# Close other GPU-intensive apps
# Check memory pressure
memory_pressure
```

## Next Steps

- [Open WebUI](open-webui.md) — Connect MLX servers to a web interface
- [Memory Management](memory-management.md) — Understanding unified memory limits
- [Model Selection](model-selection.md) — Choosing the right model for your RAM
