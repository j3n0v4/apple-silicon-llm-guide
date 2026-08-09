# The `KEEP_ALIVE=0s` Burst-Unload Pattern

## What it does

`KEEP_ALIVE=0s` tells Ollama to **unload the model from GPU memory immediately** after the last request completes. Instead of keeping the model warm for the next request (the default behavior), the model is evicted and its memory is reclaimed.

```text
Memory before request:  ~165 MB  (Ollama server, no model loaded)
Memory during request:  ~17 GB   (gemma4:26b-nvfp4 loaded)
Memory after request:   ~165 MB  (model unloaded instantly)
```

## Why this matters

### 1. Fan Noise and Thermal Management

Apple silicon Macs are fanless or have quiet fans — until you run a 30B model. Loading a large LLM pushes the GPU to its thermal limit, which means:

- **M1/M2/M3 Air (fanless):** Thermal throttling after 2-3 minutes
- **M1 Pro/Max (fans):** Fans spin up to 5000+ RPM, audible in a quiet room
- **M2/M3 Ultra (fans):** Same issue, though the larger thermal mass helps

With `KEEP_ALIVE=0s`, the model is only loaded during active inference. The rest of the time, the Mac stays cool and quiet.

### 2. Memory Availability

A 26B model at NVFP4 quantization takes ~17 GB of unified memory. On a 64GB system, that is 26% of total memory permanently consumed if the model stays loaded. With `KEEP_ALIVE=0s`, that memory is freed for other applications (browser, IDE, Docker, etc.) between requests.

### 3. Battery Life

On a MacBook, keeping a model loaded in GPU memory consumes power even when idle. The GPU memory controller must refresh the memory cells, and the model weights must be kept in a powered-on state. With `KEEP_ALIVE=0s`, the GPU memory is reclaimed and can enter a lower power state.

## Why it works on Apple silicon

The key enabler is **MLX's fast cold start**. Unlike CUDA-based systems where loading a model takes 10-30 seconds, MLX on Apple silicon can load a 30B model in ~2 seconds:

| Backend | Cold Start (26B model) | Cold Start (7B model) |
|---------|----------------------|---------------------|
| Ollama (Metal) | ~3s | ~1s |
| MLX (mlx_lm) | ~2s | ~0.5s |
| llama.cpp (Metal) | ~4s | ~1.5s |
| CUDA (NVIDIA) | ~8s | ~3s |

This makes the burst-unload pattern viable: the 2-second cold start penalty is acceptable for most interactive use cases, and the memory/power savings are substantial.

## How to configure

### Ollama

```bash
# Set globally before starting Ollama
export OLLAMA_KEEP_ALIVE=0s
ollama serve
```

Or set per-request in the API:

```bash
# Per-request KEEP_ALIVE
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:26b-nvfp4",
    "prompt": "Hello",
    "keep_alive": "0s"
  }'
```

### Persistent Configuration

Add to your shell profile:

```bash
# ~/.zshrc or ~/.bashrc
export OLLAMA_KEEP_ALIVE=0s
```

Or set it in Ollama's config:

```yaml
# ~/.ollama/config.yaml
keep_alive: 0s
```

## Trade-offs

| Aspect | KEEP_ALIVE=0s | Default (5m) | Always (∞) |
|--------|--------------|--------------|------------|
| Memory usage | ~165 MB idle | ~17 GB idle | ~17 GB always |
| Cold start latency | 2-3s per request | 0s (warm) | 0s (warm) |
| Fan noise | Minimal | Spins up after first request | Constant |
| Battery drain | Low | Moderate | High |
| Multi-model switching | Instant | Must wait for unload | Must manually unload |

## Use cases

### Burst Workloads

You send a query, wait for the response, then do something else for a while. Perfect for:
- Chat applications with infrequent messages
- Batch processing with gaps between jobs
- Interactive REPL-style use

### Multi-Model Setups

You switch between models frequently (e.g., Gemma4 for chat, DeepSeek-R1 for reasoning, Qwen3-Coder for code). With `KEEP_ALIVE=0s`, each model is loaded on demand and unloaded immediately:

```bash
# Switch between models without delay
ollama run gemma4:26b-nvfp4 "Write a poem" --keep-alive 0s
ollama run deepseek-r1:14b "Solve this math problem" --keep-alive 0s
ollama run qwen3-coder:30b "Write a Python script" --keep-alive 0s
```

Each command loads the model, runs inference, and unloads — no manual management needed.

### Battery-Powered Operation

On a MacBook away from power, every watt counts. `KEEP_ALIVE=0s` ensures the GPU is only active during actual inference.

### Real-Time Applications

If you need sub-100ms response times for every query (e.g., a voice assistant), keep the model loaded. The 2-3s cold start penalty is unacceptable for real-time use.

### High-Throughput Serving

If you are serving hundreds of requests per minute, the overhead of loading/unloading the model for each request will kill throughput. Keep the model loaded.

## Monitoring

To verify the pattern is working:

```bash
# Check memory before and after a request
# Terminal 1: Monitor memory
memory_pressure

# Terminal 2: Run a request
ollama run gemma4:26b-nvfp4 "Hello" --keep-alive 0s

# Check memory again — should be back to baseline
memory_pressure
```

Memory pressure spikes during the request and returns to baseline immediately after.

## Implementation in code

```python
import openai
import time

client = openai.OpenAI(base_url="http://localhost:11434/v1", api_key="ollama")

def burst_chat(prompt: str):
    """Send a request with KEEP_ALIVE=0s for burst-unload behavior."""

    start = time.time()

    response = client.chat.completions.create(
        model="gemma4:26b-nvfp4",
        messages=[{"role": "user", "content": prompt}],
        extra_body={"keep_alive": "0s"}  # Ollama-specific parameter
    )

    elapsed = time.time() - start
    content = response.choices[0].message.content

    print(f"Response in {elapsed:.2f}s (includes ~2s cold start)")
    return content

# First request: ~3s (cold start + inference)
print(burst_chat("Hello"))

# Second request: ~3s again (cold start again — model was unloaded)
print(burst_chat("Hi again"))
```

## Recommendation

Use `KEEP_ALIVE=0s` for:
- Interactive use where queries are spaced >30 seconds apart
- Multi-model workflows
- Battery-powered operation
- Systems with <64GB memory

Keep the default (5 minute keep-alive) for:
- Real-time applications
- High-throughput serving
- When you are actively working with the model for extended periods
