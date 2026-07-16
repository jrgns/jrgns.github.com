---
title: "Benchmarking vLLM on 2× RTX 3090: Setup and Aim"
date: 2026-07-16
description: "Hardware, software, and methodology for a systematic TP=2 coding model sweep on an Ampere dual-GPU rig — what the sweep does, how it works, and what 'best config' actually means."
draft: true
---

<!-- SECTION 1: The machine -->

## The Machine

<!-- - Host: orion, 2× RTX 3090, 24 GiB VRAM per GPU, Ampere architecture (sm_86) -->
<!-- - PCIe topology pre-NVLink (PHB); NVLink bridge installed 2026-07-11 (NV3, 3-link bond) -->
<!-- - CPU, RAM, storage: [fill in] -->
<!-- - GPU interconnect verification: `nvidia-smi topo -m` (PHB → NV3) -->

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

<!-- - qwen3-coder-30b (MoE, 30.5B/3.3B, coding specialist, non-thinking) → winner candidate -->
<!-- - qwen36-35b-a3b (MoE+vision, 35B/3B, multimodal, thinking mode) -->
<!-- - qwen3-coder-next-60b-ream (MoE, ~60B, REAP-compressed, coding) -->
<!-- - glm47-flash (MoE, 23B/3B, coding, requires `--kv-cache-dtype auto`) -->
<!-- - devstral-24b-gptq (Dense, 24B, Mistral lineage, INT4/INT8 GPTQ) -->
<!-- - devstral-24b-fp8 (Dense, 24B, Mistral lineage, FP8 native) -->
<!-- - qwen36-27b (Dense, 32.8B, general-purpose, `--language-model-only` option) -->
<!-- - gpt-oss-20b (Dense, 20B, general-purpose, `--enforce-eager` needed on original image) -->
<!-- - qwen3-coder-next-80b (MoE, 80B — OOMs in all attempts) -->

<!-- SECTION 10: The story arc -->

## The Story This Sweep Tells

<!-- This is three posts: -->
<!-- 1. [this post] — Setup, aim, methodology -->
<!-- 2. Pre-NVLink (PCIe) — what worked, what didn't, why dense models failed -->
<!-- 3. Post-NVLink — the hardware change that flipped the verdict -->
<!-- The through-line: TP=2 on a $3K dual-3090 rig can produce production-quality coding models. The question is which models, at what latency, and whether NVLink makes the difference between "viable" and "dead." -->
