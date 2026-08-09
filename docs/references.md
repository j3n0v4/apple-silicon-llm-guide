# References

A curated index of official project sites, benchmark resources, research
papers, model publishers, quantization references, and community tools for
running LLMs on Apple silicon.

---

## Official project sites

### Ollama

| Resource | URL | Description |
|---|---|---|
| **Ollama** | [https://ollama.com](https://ollama.com) | The easiest way to run LLMs locally. One-click install, model library, OpenAI-compatible API, Metal GPU acceleration. |
| **Ollama GitHub** | [https://github.com/ollama/ollama](https://github.com/ollama/ollama) | Source code, issues, feature requests, and release notes. |
| **Ollama Model Library** | [https://ollama.com/library](https://ollama.com/library) | Browse and search available models. |
| **Ollama Docs** | [https://github.com/ollama/ollama/tree/main/docs](https://github.com/ollama/ollama/tree/main/docs) | Official documentation — API reference, modelfiles, configuration. |

### MLX (Apple)

| Resource | URL | Description |
|---|---|---|
| **MLX** | [https://github.com/ml-explore/mlx](https://github.com/ml-explore/mlx) | Apple's machine learning framework for Apple silicon. NumPy-like API with GPU acceleration. |
| **MLX Examples** | [https://github.com/ml-explore/mlx-examples](https://github.com/ml-explore/mlx-examples) | Example scripts: LLM inference, fine-tuning, text-to-image, speech recognition. |
| **MLX Community Models** | [https://huggingface.co/mlx-community](https://huggingface.co/mlx-community) | Pre-converted MLX models on Hugging Face. |
| **mlx-lm** | [https://github.com/ml-explore/mlx-lm](https://github.com/ml-explore/mlx-lm) | LLM inference and fine-tuning with MLX. Includes `mlx_lm.server` for OpenAI-compatible serving. |

### Hugging Face

| Resource | URL | Description |
|---|---|---|
| **Hugging Face** | [https://huggingface.co](https://huggingface.co) | The primary hub for open-source models, datasets, and ML tools. |
| **Hugging Face Docs** | [https://huggingface.co/docs](https://huggingface.co/docs) | API reference, model hub guide, inference endpoints. |
| **Transformers** | [https://github.com/huggingface/transformers](https://github.com/huggingface/transformers) | The de-facto library for loading and running transformer models. |

### Open WebUI

| Resource | URL | Description |
|---|---|---|
| **Open WebUI** | [https://openwebui.com](https://openwebui.com) | ChatGPT-like interface for local LLMs. Supports Ollama and OpenAI-compatible backends. |
| **Open WebUI GitHub** | [https://github.com/open-webui/open-webui](https://github.com/open-webui/open-webui) | Source code, issues, feature requests. |

### MLX Serving Tools

| Resource | URL | Description |
|---|---|---|
| **Rapid-MLX** | [https://github.com/raullenchai/Rapid-MLX](https://github.com/raullenchai/Rapid-MLX) | Faster MLX inference engine with optimized kernels. |
| **oMLX** | [https://github.com/motsognirr/olmlx](https://github.com/motsognirr/olmlx) | Ollama-compatible server using MLX as the inference backend. Drop-in replacement for Ollama. |
| **mlx-omni-server** | [https://github.com/madroidmaq/mlx-omni-server](https://github.com/madroidmaq/mlx-omni-server) | Multi-model MLX server with OpenAI-compatible API, vision support, and tool calling. |

### Monitoring & Diagnostics

| Resource | URL | Description |
|---|---|---|
| **macmon** | [https://github.com/vladkens/macmon](https://github.com/vladkens/macmon) | Sudoless Apple silicon thermal and power monitoring — CPU/GPU frequency, temperature, power draw. |
| **Activity Monitor** | Built into macOS | Monitor GPU usage, memory pressure, and energy impact during inference. |

---

## Benchmark & performance sites

| Resource | URL | Description |
|---|---|---|
| **CraftRigs** | [https://www.craftrigs.com](https://www.craftrigs.com) | Community LLM benchmark database with Apple silicon results. Filter by model, quantization, and hardware. |
| **WillItRunAI** | [https://willitrunai.com](https://willitrunai.com) | Check if a model fits on your hardware. Enter model size and RAM to see feasibility. |
| **LLMCheck** | [https://llmcheck.net](https://llmcheck.net) | LLM performance database with Apple silicon-specific benchmarks. |
| **EastonDev** | [https://eastondev.com](https://eastondev.com) | Apple silicon LLM benchmarks and guides. Regular updates with new model releases. |
| **Vijay.eu** | [https://vijay.eu](https://vijay.eu) | Apple silicon ML benchmarks — token speeds, memory usage, and hardware comparisons. |
| **r/LocalLLaMA** | [https://reddit.com/r/LocalLLaMA](https://reddit.com/r/LocalLLaMA) | The primary Reddit community for local LLM discussion. Extensive Apple silicon benchmark threads. |

---

## Research papers & technical articles

| Title | URL | Description |
|---|---|---|
| **SwiftLM on M1 Max** | [https://arxiv.org/abs/2305.11206](https://arxiv.org/abs/2305.11206) | Early research on LLM inference optimization for Apple silicon. |
| **mlx-omni-server** | [https://github.com/madroidmaq/mlx-omni-server](https://github.com/madroidmaq/mlx-omni-server) | Technical article on building a multi-model MLX server with vision and tool-calling support. |
| **Flash Attention on Apple silicon** | [https://github.com/ml-explore/mlx/issues/1234](https://github.com/ml-explore/mlx/issues/1234) | MLX issue tracking flash attention implementation status and performance. |
| **Metal Performance Shaders** | [https://developer.apple.com/documentation/metalperformanceshaders](https://developer.apple.com/documentation/metalperformanceshaders) | Apple's GPU compute framework used by both Ollama and MLX for accelerated inference. |
| **GGUF Specification** | [https://github.com/ggerganov/ggml/blob/master/docs/gguf.md](https://github.com/ggerganov/ggml/blob/master/docs/gguf.md) | The GGUF binary format specification used by llama.cpp and Ollama. |
| **Apple silicon Memory Bandwidth** | [https://en.wikipedia.org/wiki/Apple_silicon#Memory](https://en.wikipedia.org/wiki/Apple_silicon#Memory) | Wikipedia reference for Apple silicon memory bandwidth figures by chip generation. |

---

## Known Ollama issues (GitHub)

These are the most relevant open/closed issues for Apple silicon users:

| Issue | URL | Description |
|---|---|---|
| **#14493** | [https://github.com/ollama/ollama/issues/14493](https://github.com/ollama/ollama/issues/14493) | Metal memory leak on M-series chips during long inference sessions. |
| **#14601** | [https://github.com/ollama/ollama/issues/14601](https://github.com/ollama/ollama/issues/14601) | Flash attention not enabled by default on Apple silicon. |
| **#14745** | [https://github.com/ollama/ollama/issues/14745](https://github.com/ollama/ollama/issues/14745) | KV cache quantization issues with certain model architectures. |
| **#15866** | [https://github.com/ollama/ollama/issues/15866](https://github.com/ollama/ollama/issues/15866) | Context length limit not properly enforced, causing OOM on Apple silicon. |
| **#16282** | [https://github.com/ollama/ollama/issues/16282](https://github.com/ollama/ollama/issues/16282) | `/no_think` tag not working with certain thinking models. |
| **#16698** | [https://github.com/ollama/ollama/issues/16698](https://github.com/ollama/ollama/issues/16698) | Model loading fails on M4 with large context windows. |
| **PR #14878** | [https://github.com/ollama/ollama/pull/14878](https://github.com/ollama/ollama/pull/14878) | Pull request adding improved Metal kernel support for M3/M4 chips. |

---

## Model publishers

These publishers provide pre-quantized models optimized for Apple silicon:

| Publisher | Hugging Face | Description |
|---|---|---|
| **mannix** | [https://huggingface.co/mannix](https://huggingface.co/mannix) | GGUF quantized models with detailed benchmark notes. |
| **charaf** | [https://huggingface.co/charaf](https://huggingface.co/charaf) | MLX community model conversions and fine-tuned variants. |
| **mlx-community** | [https://huggingface.co/mlx-community](https://huggingface.co/mlx-community) | Official MLX model conversion repository. Hundreds of models in 4-bit and 8-bit MLX format. |
| **lmstudio-community** | [https://huggingface.co/lmstudio-community](https://huggingface.co/lmstudio-community) | GGUF quantized models curated for LM Studio. |

---

## Quantization references

| Format | Description | Typical Size Reduction |
|---|---|---|
| **GGUF** | llama.cpp's native format. Supports many quantization levels (Q2_K through Q8_0). Most widely supported across tools. | 4×–8× vs. FP16 |
| **NVFP4** | NVIDIA-style 4-bit floating point. High-quality quants for Apple silicon. | ~4× vs. FP16 |
| **MXFP8** | Microscaling FP8 format. Emerging standard for 8-bit inference with minimal quality loss. | ~2× vs. FP16 |
| **Q4_K_M** | GGUF 4-bit quantization with medium importance grouping. Best quality-to-size ratio for most models. | ~4× vs. FP16 |
| **Q8_0** | GGUF 8-bit quantization. Minimal quality loss, higher memory usage. | ~2× vs. FP16 |
| **MLX 4-bit** | MLX-native 4-bit quantization. Uses Apple's Metal Performance Shaders. | ~4× vs. FP16 |
| **MLX 8-bit** | MLX-native 8-bit quantization. Near-lossless quality. | ~2× vs. FP16 |

### Quantization Selection Guide

| Your RAM | Max Model Size (FP16) | Recommended Quantization |
|---|---|---|
| 16 GB | 7B–8B | Q4_K_M or NVFP4 |
| 32 GB | 13B–15B | Q4_K_M or NVFP4 |
| 64 GB | 27B–30B | Q4_K_M, NVFP4, or MXFP8 |
| 128 GB | 70B+ | Q4_K_M or Q8_0 for smaller models |
| 192 GB | 120B+ | Q4_K_M for largest models |

---

## Apple silicon hardware references

### Identifying Your Hardware

```bash
# Chip type and model
sysctl -n machdep.cpu.brand_string

# Unified memory size (in bytes)
sysctl -n hw.memsize

# Memory bandwidth (approximate, in GB/s)
# M1: 68.25 (Pro/Max: 200/400)
# M2: 100 (Pro/Max: 200/400)
# M3: 150 (Pro/Max: 300/400)
# M4: 120 (Pro/Max: 240/480)

# GPU core count
system_profiler SPDisplaysDataType | grep "Total Number of Cores"

# Metal GPU family support
system_profiler SPDisplaysDataType | grep "Metal"
```

### Memory Bandwidth by Chip

| Chip | Base (GB/s) | Pro (GB/s) | Max (GB/s) | Ultra (GB/s) |
|---|---|---|---|---|
| M1 | 68.25 | 200 | 400 | 800 |
| M2 | 100 | 200 | 400 | 800 |
| M3 | 150 | 300 | 400 | — |
| M4 | 120 | 240 | 480 | — |

Memory bandwidth is the key hardware factor for LLM inference
speed on Apple silicon — it determines how fast model weights can be fed to the
GPU.

### IOKit / Metal Performance Shaders

```bash
# GPU statistics (power, utilization, temperature)
sudo powermetrics --samplers gpu_power -n 1 -i 1000

# Metal device info
system_profiler SPDisplaysDataType
```

---

## Alternative platforms

These tools also support running LLMs on Apple silicon for different
workflows:

| Platform | URL | Description |
|---|---|---|
| **LM Studio** | [https://lmstudio.ai](https://lmstudio.ai) | GUI application for discovering, downloading, and running GGUF models. Built-in chat interface and local API server. |
| **Jan** | [https://jan.ai](https://jan.ai) | Open-source ChatGPT alternative that runs entirely offline. Supports multiple inference engines. |
| **AnythingLLM** | [https://anythingllm.com](https://anythingllm.com) | All-in-one AI desktop app with RAG support. Can use local models. |
| **Khoj** | [https://khoj.dev](https://khoj.dev) | Open-source AI copilot that runs locally. Supports search, chat, and agent features. |
| **LocalAI** | [https://localai.io](https://localai.io) | Self-hosted OpenAI API alternative. Supports multiple backends including llama.cpp and MLX. |
| **llama.cpp** | [https://github.com/ggerganov/llama.cpp](https://github.com/ggerganov/llama.cpp) | The C/C++ inference engine that powers Ollama. Can be used directly for maximum control. |
| **vLLM** | [https://github.com/vllm-project/vllm](https://github.com/vllm-project/vllm) | High-throughput LLM serving engine. Limited Apple silicon support but improving. |
| **ExLlamaV2** | [https://github.com/turboderp/exllamav2](https://github.com/turboderp/exllamav2) | Fast inference for Llama-family models. Primarily CUDA-focused but has experimental Metal support. |

---

## Community & discussion

| Resource | URL | Description |
|---|---|---|
| **r/LocalLLaMA** | [https://reddit.com/r/LocalLLaMA](https://reddit.com/r/LocalLLaMA) | The largest community for local LLM discussion. Active Apple silicon threads daily. |
| **MLX Discord** | [https://discord.gg/mlx](https://discord.gg/mlx) | Community Discord for MLX framework discussion and support. |
| **Ollama Discord** | [https://discord.gg/ollama](https://discord.gg/ollama) | Official Ollama Discord for troubleshooting and discussion. |
| **Hugging Face Discord** | [https://discord.gg/huggingface](https://discord.gg/huggingface) | Hugging Face community Discord with dedicated local-inference channels. |

---

## Contributing

Found a broken link, missing resource, or new benchmark site? Open an issue or
pull request on GitHub:

[https://github.com/j3n0v4/apple-silicon-llm-guide](https://github.com/j3n0v4/apple-silicon-llm-guide)

---

*Last updated: August 2026. URLs and project statuses change over time. If a link is
broken, please open an issue.*
