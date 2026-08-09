# Benchmark Methodology

This page documents how all benchmarks in this project were conducted — the test battery, measurement approach, hardware configuration, and scripts used. Follow these instructions to reproduce the results on your own machine.

> **Verified on:** MacBook Pro M1 Max (64 GB), macOS 26.6 (Tahoe).

## Hardware configuration

### Test Machine

| Component | Specification |
|-----------|--------------|
| **Machine** | MacBook Pro (2021) |
| **SoC** | Apple M1 Max |
| **CPU** | 10 cores (8 performance + 2 efficiency) |
| **GPU** | 24 cores |
| **Unified Memory** | 64 GB |
| **OS** | macOS 26.6 |
| **Storage** | 2 TB SSD (APFS) |
| **Thermal** | Passive cooling (laptop chassis) |

### Software Versions

| Software | Version |
|----------|---------|
| Ollama | 0.6.x |
| MLX | 0.28.x |
| mlx-lm | 0.28.x |
| Rapid-MLX | 0.3.x |
| oMLX | 0.2.x |
| Python | 3.12.x |

## Measurement approach

### Throughput Measurement

Throughput is measured as **tokens per second during generation only** (prefill excluded) unless otherwise noted.

```python
import time
import ollama

def measure_throughput(model, prompt, max_tokens=512):
    """Measure generation throughput in tok/s."""
    start = time.time()
    first_token_time = None
    token_count = 0

    stream = ollama.generate(
        model=model,
        prompt=prompt,
        stream=True,
        options={"num_predict": max_tokens}
    )

    for chunk in stream:
        if first_token_time is None:
            first_token_time = time.time()
        if chunk.get("response"):
            token_count += 1

    end = time.time()

    generation_time = end - first_token_time
    throughput = token_count / generation_time if generation_time > 0 else 0

    return {
        "throughput_tok_per_s": round(throughput, 2),
        "cold_start_s": round(first_token_time - start, 2),
        "total_time_s": round(end - start, 2),
        "tokens_generated": token_count
    }
```

### Cold Start Measurement

Cold start is the time from sending the first request to receiving the **first token**. This includes:

1. Model loading (if not cached in memory)
2. Prompt processing / prefill
3. First token generation

Cold start is measured as `first_token_time - request_start_time` in the script above.

### Effective Throughput

Effective throughput accounts for **all tokens** (prefill + generation) divided by total wall time:

```text
effective_throughput = (prompt_tokens + generated_tokens) / total_time
```

This is the metric that matters for real-world latency perception. A model with fast generation but slow prefill can feel sluggish in interactive use.

### Quality Scoring

Quality scores (1–10) are based on:

1. **Reasoning quality:** Ability to follow complex multi-step instructions
2. **Coherence:** Output consistency and logical flow
3. **Instruction following:** Adherence to system prompts and formatting requirements
4. **Factual accuracy:** Correctness of generated information (on known topics)

Scores are averaged across a test suite of 50 prompts covering chat, coding, reasoning, and creative tasks.

### Perplexity Measurement

Perplexity is measured on a held-out validation set of 1,000 documents (not seen during training):

```bash
# Using llama.cpp's perplexity tool
./perplexity -m model.gguf -f validation_set.bin -ngl 99

# Using MLX's perplexity tool
mlx_lm.perplexity --model model-path --data validation_set.txt
```

## Test battery

### Standard Test Prompt

All throughput benchmarks use a standardized prompt:

```text
You are a helpful assistant. Please provide a detailed response to the following:

[2,000 tokens of structured context — technical documentation, code snippets, and natural language]

Based on the above, explain the key architectural decisions and their tradeoffs.
```

This prompt ensures:
- Consistent prefill load (2,000 tokens)
- Realistic context for generation
- Comparable across all models

### Generation Length

All throughput tests generate **512 tokens** unless otherwise noted. This is long enough to measure stable generation speed but short enough to avoid context window issues.

### Repetition and Reporting

Each test is run **5 times** and the **median** value is reported. This mitigates variance from:

- Thermal throttling (though not observed on the M1 Max laptop)
- System background processes
- Memory pressure from other applications
- First-run vs cached model loading

## Test scripts

The full benchmark suite script is available in the project repository. Key measurement functions:

### Throughput Measurement

```python
import time
import ollama

def measure_throughput(model, prompt, max_tokens=512):
    """Measure generation throughput in tok/s."""
    start = time.time()
    first_token_time = None
    token_count = 0

    stream = ollama.generate(
        model=model,
        prompt=prompt,
        stream=True,
        options={"num_predict": max_tokens}
    )

    for chunk in stream:
        if first_token_time is None:
            first_token_time = time.time()
        if chunk.get("response"):
            token_count += 1

    end = time.time()

    generation_time = end - first_token_time
    throughput = token_count / generation_time if generation_time > 0 else 0

    return {
        "throughput_tok_per_s": round(throughput, 2),
        "cold_start_s": round(first_token_time - start, 2),
        "total_time_s": round(end - start, 2),
        "tokens_generated": token_count
    }
```

### MLX Engine Comparison Script

```python
#!/usr/bin/env python3
"""Compare MLX engines on the same model."""

import subprocess
import time
import json
import requests

MODEL = "Qwen3.5-35B-A3B-abliterated-4bit"
PROMPT = "Explain the key differences between RISC-V and ARM architectures."
MAX_TOKENS = 512

engines = {
    "mlx_lm": {
        "start": ["mlx_lm.server", "--model", MODEL, "--port", "8080"],
        "endpoint": "http://localhost:8080/v1/completions"
    },
    "rapid-mlx": {
        "start": ["rapid-mlx", "serve", "--model", MODEL, "--port", "8081"],
        "endpoint": "http://localhost:8081/v1/completions"
    },
    "omlx": {
        "start": ["omlx", "serve", "--model", MODEL, "--port", "8082"],
        "endpoint": "http://localhost:8082/v1/completions"
    }
}

def measure_engine(name, config):
    """Start engine, send request, measure, stop."""
    process = subprocess.Popen(
        config["start"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    # Wait for server to be ready
    time.sleep(5)

    start = time.time()
    response = requests.post(
        config["endpoint"],
        json={
            "prompt": PROMPT,
            "max_tokens": MAX_TOKENS,
            "stream": False
        }
    )
    total_time = time.time() - start

    data = response.json()
    tokens = len(data.get("choices", [{}])[0].get("text", "").split())

    process.terminate()
    process.wait()

    return {
        "engine": name,
        "total_time_s": round(total_time, 2),
        "tokens_generated": tokens,
        "throughput_tok_per_s": round(tokens / total_time, 2)
    }

# Run for each engine
results = []
for name, config in engines.items():
    print(f"Testing {name}...")
    result = measure_engine(name, config)
    results.append(result)
    print(f"  {result['throughput_tok_per_s']} tok/s")

print(json.dumps(results, indent=2))
```

## Memory measurement

### KV Cache Size

KV cache size is measured by:

1. Loading the model with a specific context length
2. Sending a prompt that fills the context window
3. Reading the process's memory usage before and after generation
4. The difference is the KV cache size

```bash
# Measure KV cache for a model at 128K context
ollama run gemma4:e4b-nvfp4 --context-length 131072

# In another terminal, measure memory
ps aux | grep ollama | awk '{print $6}'  # RSS in KB
```

### Total Memory Budget

Total memory budget = model file size (on disk) + KV cache (at target context length) + ~5% overhead for runtime structures.

## Reproducibility notes

### Factors That Affect Results

1. **Thermal state:** A cold machine shows different results than one that has been running for hours. The M1 Max laptop maintains consistent performance under sustained load.
2. **Background processes:** Close browsers, IDEs, and other memory-intensive applications before benchmarking.
3. **Model cache:** Ollama caches loaded models. First request after a restart includes model loading time; subsequent requests skip it.
4. **Prompt structure:** Different prompts of the same length can have different prefill times due to attention pattern differences.
5. **Random seeds:** Generation is deterministic with a fixed seed. Set `seed: 42` in Ollama options for reproducible results.

### Ensuring Reproducibility

```bash
# Set a fixed seed for deterministic generation
ollama run gemma4:e4b-nvfp4 --seed 42

# Clear model cache before first measurement
ollama stop gemma4:e4b-nvfp4

# Monitor system state
memory_pressure
```

## Data collection date

All benchmarks in this project were collected on **August 1, 2026**. Results differ with newer software versions, model updates, or different hardware configurations.
