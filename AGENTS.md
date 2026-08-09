# Agents

This file provides guidance for AI agents (and human contributors) working with this repository.

## Project overview

apple-silicon-llm-guide is a community guide sharing benchmarks, setup knowledge, and workarounds for running LLMs on Apple Silicon. Built with MkDocs Material and deployed to GitHub Pages.

## Repository structure

- `docs/` — MkDocs source content (Markdown pages)
- `docs/benchmarks/` — Benchmark data and methodology
- `docs/guides/` — Setup guides (Ollama, MLX, Open WebUI, etc.)
- `docs/workarounds/` — Known bugs and fixes
- `docs/architecture/` — Design patterns (burst/unload, serving comparison)
- `scripts/` — Swap-guard utility (launchd agent + installer)
- `mkdocs.yml` — Site configuration
- `pyproject.toml` — Python project metadata
- `Makefile` — Common targets (install, serve, build, deploy, clean, lint, rebuild)
- `LICENSE` — MIT license

## Conventions

- **Voice:** First-person singular in the origin story ("Why this exists") only. Declarative 3rd person or imperative everywhere else.
- **Headers:** Sentence-case H2 (`## Quick start`, not `## Quick Start`).
- **No invented jargon.** Use standard section names.
- **No "this guide"** — use "this repo" or "this project" instead.
- **No "Best for:" repetition** — max 1 per project.
- **Benchmark-first philosophy:** Self-measured data stands on its own. No external citations to validate own benchmarks.
- **No AI product names** in OPSEC-sensitive contexts (Hermes, Nous, etc.). Ollama, MLX, and Open WebUI are the products discussed — fine to name.
- **Model names:** Use the Ollama tag format (`gemma4:e4b-nvfp4`, `qwen3-coder:30b`) consistently.

## Building locally

```bash
make install   # install deps (mkdocs-material and friends) into the active venv
make serve     # live-reload dev server (default http://127.0.0.1:8000)
make build     # static build into site/
make rebuild   # clean + build
```

## Pre-push checks

- Run `make build` / `mkdocs build --strict` before pushing
- Verify all internal links resolve
- Verify model names are consistent between README and docs/
- Verify benchmark numbers match between README summary and docs/benchmarks/
