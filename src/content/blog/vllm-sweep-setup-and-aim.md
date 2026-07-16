---
title: "Benchmarking vLLM on 2× RTX 3090: Setup and Aim"
date: 2026-07-16
description: "Hardware, software, and methodology for a systematic TP=2 coding model sweep on an Ampere dual-GPU rig — what the sweep does, how it works, and what 'best config' actually means."
draft: true
---

## The Machine

| Component | Specification |
|---|---|
| Host | orion |
| GPU | 2× NVIDIA GeForce RTX 3090, 24 GiB VRAM each |
| Architecture | Ampere, sm_86 |
| Driver / CUDA | 595.71.05 / CUDA 13.2 |
| VBIOS | 94.02.42.00.A7 |
| CPU | AMD Ryzen 9 3900 (12 cores / 24 threads, 4.36 GHz boost) |
| RAM | 62 GiB DDR4 (~45 GiB available during sweep runs) |
| Storage | Crucial MX500 500 GB SATA SSD (296 GB free) |
| Interconnect | PCIe host bridge (PHB) → NVLink bridge (NV3, 3-link bond) installed 2026-07-11 |

<!-- SECTION 2: Why TP=2 -->

## Why TP=2 (Tensor Parallelism at Two)

<!-- - TP=2 on the 3090s doubles the KV pool (48 GiB total) → enables 192K–256K context -->
<!-- - TP=2 does NOT double decode throughput on PCIe — every prefill pays an all-reduce penalty -->
<!-- - On PCIe: TP=2 is a context play, not a throughput play -->
<!-- - Post-NVLink: TP=2 becomes a net win across both axes -->

<!-- SECTION 3: vLLM, Docker, image choice -->

## vLLM and the Docker Image

<!-- - Image: `vllm/vllm-openai:latest` (primary); `vllm/vllm-openai:nightly` for gpt-oss retest -->
<!-- - vLLM's custom all-reduce kernel crashes on sm_86 (`custom_all_reduce.cuh:455 'invalid argument'`) -->
<!-- - All sweeps run `--disable-custom-all-reduce` → NCCL handles the all-reduce -->
<!-- - On PCIe: NCCL forces `NCCL_P2P_DISABLE=1` → all-reduce goes over PCIe host bridge -->
<!-- - On NVLink: NCCL routes all-reduce over the NVLink bridge (no P2P disable) -->
<!-- - Per-model `--kv-cache-dtype auto` needed on sm_86 for models with grouped-attention kernels (GLM, gpt-oss original) → `fp8e4nv` unsupported on Ampere for those attention paths -->

<!-- SECTION 4: Portainer → llama-swap migration -->

## From Portainer to llama-swap

<!-- - Previous deployment: Portainer docker-compose stack (Stack ID 82, now Inactive) -->
<!-- - Migration: native `llama-swap.service` (systemd, router on :8181, config at `/etc/llama-swap/config.yml`) -->
<!-- - Whisper ASR remains on :8000 -->
<!-- - Practical effect: sweep stops `llama-swap.service` to free GPUs, restores it after -->
<!-- - `sudo systemctl stop/start llama-swap.service` — requires interactive sudo -->

<!-- SECTION 5: The sweep orchestrator -->

## The Sweep Orchestrator: `vllm-sweep.sh`

<!-- - Single Bash file — drives `docker run` + the container's own `vllm bench serve` -->
<!-- - Not Python/venv; no Portainer state; runs on orion only -->
<!-- - Deploy: `scp -r vllm-sweep orion:~/` -->
<!-- - Core variables: `IMAGE=`, `FIXED_ARGS=`, `M_EXTRA[]` (per-model overrides) -->
<!-- - Guardrails: always `--run-dir ~/vllm-sweep/runs/<ts>`, always `--prepull` for uncached weights -->
<!-- - Container lifecycle: create → pull → run bench → teardown → `result.json` + `RESULTS.md` -->

<!-- SECTION 6: Sweep stages -->

## The Six Sweep Stages

<!-- Coordinate descent across four knobs: utilization, max-model-len, max-num-seqs, batch size. Six phases, each refining the configuration space. -->

| Stage | Name | What it sweeps | Anchor |
|---|---|---|---|
| S0 | Anchor | Best config at baseline context (32K) | util=0.90 |
| S1 | Batched | Batch-size ladder at S0's best | — |
| S2 | Seqs | Max-num-seqs ladder | — |
| S3 | Length | `max-model-len` ladder (32K → ceiling) | — |
| S4 | Util | Utilization ladder (push above anchor) | — |
| S5 | LM-only | Language-model-only flag (drops vision tower) | — |
| S6 | Context ceiling | Keep increasing `max-model-len` until first failure | — |

<!-- - Tier `quick` = S0 + 2 light points + S6 → fast viability check -->
<!-- - Each config produces: `decode tok/s`, `TTFT p50 ms`, `TPOT p50 ms`, `max usable ctx`, `KV tokens @ config` -->
<!-- - `result.json` reason codes: `ok`, `oom`, `crash`, `timeout`, `over_budget` -->

<!-- SECTION 7: Winner criteria -->

## How the Winner Is Chosen

<!-- - Winner = highest decode tok/s whose median TTFT (input=4096 tokens, concurrency=1) is under `TTFT_BUDGET_MS` (default 2500 ms) -->
<!-- - Ties broken toward larger `max usable context` -->
<!-- - The TTFT budget is a prefill-latency gate — a model that serves fast but takes 5 seconds to start answering is useless for agentic coding -->
<!-- - Decode speed is measured at concurrency 1 (single-user coding) — concurrency scaling is reported separately -->

<!-- SECTION 8: What the sweep does NOT do -->

## What This Sweep Does Not Do

<!-- - Does not modify inference serving — report only, never touches llama-swap config -->
<!-- - Does not test concurrency beyond c1 decode + c4 aggregate (reported in `combined-summary.md`) -->
<!-- - Does not benchmark multi-model co-location (that's a llama-swap config question) -->
<!-- - Does not run on hardware other than orion's 2× RTX 3090s -->
<!-- - Does not test quantization variants beyond what's in the roster (AWQ, GPTQ, FP8, REAP) -->

<!-- SECTION 9: The roster -->

## Models in the Sweep

| Model | Type | Params | Notes | Sweep outcome |
|---|---|---|---|---|
| qwen3-coder-30b | MoE | 30.5B / 3.3B active | Coding specialist, non-thinking | Winner candidate |
| qwen36-35b-a3b | MoE+vision | 35B / 3B active | Multimodal, thinking mode | Viable (vision tower active) |
| qwen3-coder-next-60b-ream | MoE | ~60B total | REAP-compressed, coding | Viable at 256K context |
| glm47-flash | MoE | 23B / 3B active | Coding agent | Requires `--kv-cache-dtype auto` on Ampere |
| devstral-24b-gptq | Dense | 24B | Mistral lineage, INT4/INT8 GPTQ | TTFT over budget on PCIe |
| devstral-24b-fp8 | Dense | 24B | Mistral lineage, FP8 native | TTFT over budget on PCIe |
| qwen36-27b | Dense | 32.8B | General-purpose, `--language-model-only` option | TTFT floor ~4.2s on PCIe TP=2 |
| gpt-oss-20b | Dense | 20B | General-purpose | Needs nightly image; original requires `--enforce-eager` |
| qwen3-coder-next-80b | MoE | ~80B | — | OOM in all attempts |

<!-- SECTION 10: The story arc -->

## The Story This Sweep Tells

<!-- This is three posts: -->
<!-- 1. [this post] — Setup, aim, methodology -->
<!-- 2. Pre-NVLink (PCIe) — what worked, what didn't, why dense models failed -->
<!-- 3. Post-NVLink — the hardware change that flipped the verdict -->
<!-- The through-line: TP=2 on a $3K dual-3090 rig can produce production-quality coding models. The question is which models, at what latency, and whether NVLink makes the difference between "viable" and "dead." -->

## External Resources

**Models on Hugging Face**

These are the actual model IDs loaded by `llama-swap` on orion — the exact quantised builds used in production and sweeps.

| Model | Hugging Face |
|---|---|
| qwen3-coder-30b | [cyankiwi/Qwen3-Coder-30B-A3B-Instruct-AWQ-4bit](https://huggingface.co/cyankiwi/Qwen3-Coder-30B-A3B-Instruct-AWQ-4bit) |
| qwen36-35b-a3b | [cyankiwi/Qwen3.6-35B-A3B-AWQ-4bit](https://huggingface.co/cyankiwi/Qwen3.6-35B-A3B-AWQ-4bit) |
| qwen3-coder-next-60b-ream | [cyankiwi/Qwen3-Coder-Next-REAM-AWQ-4bit](https://huggingface.co/cyankiwi/Qwen3-Coder-Next-REAM-AWQ-4bit) |
| glm47-flash | [cyankiwi/GLM-4.7-Flash-REAP-23B-A3B-AWQ-4bit](https://huggingface.co/cyankiwi/GLM-4.7-Flash-REAP-23B-A3B-AWQ-4bit) |
| qwen36-27b | [cyankiwi/Qwen3.6-27B-AWQ-INT4](https://huggingface.co/cyankiwi/Qwen3.6-27B-AWQ-INT4) |
| gpt-oss-20b | [openai/gpt-oss-20b](https://huggingface.co/openai/gpt-oss-20b) |
| devstral-24b | [mistralai/Devstral-Small-2507](https://huggingface.co/mistralai/Devstral-Small-2507) — sweep-only, not deployed |
| qwen3-coder-next-80b | [Qwen/Qwen3-Coder-Next](https://huggingface.co/Qwen/Qwen3-Coder-Next) — OOMs on 2× 24 GB, never deployed |

**Documentation**

- [vLLM documentation](https://docs.vllm.ai/) — Docker images, benchmark CLI, tensor parallelism, `--kv-cache-dtype`
- [NCCL documentation](https://docs.nvidia.com/deeplearning/nccl/user-guide/) — all-reduce, P2P, multi-GPU communication
- [CUDA Toolkit 13.2](https://developer.nvidia.com/cuda-toolkit) — CUDA runtime used by the `vllm/vllm-openai:latest` Docker image
- [NVIDIA Ampere architecture](https://www.nvidia.com/en-us/geforce/graphics-cards/30-series/rtx-3090/) — sm_86 compute capability, `fp8e4nv` support notes

**Community**

- [3090 Club](https://github.com/noonghunna/club-3090) — community recipes for serving LLMs on RTX 3090/4090/5090; multi-engine (vLLM, llama.cpp, SGLang); OpenAI-compatible API configs
