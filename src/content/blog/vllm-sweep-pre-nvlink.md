---
title: "Benchmarking vLLM on 2× RTX 3090 — Pre-NVLink: What PCIe Costs You"
date: 2026-07-16
description: "Six sweeps on 2× RTX 3090 without NVLink — which coding models actually work at TP=2, what the TTFT floor is, and why dense models fail without the bridge."
draft: true
---

<!-- SECTION 1: The PCIe reality -->

## The PCIe Baseline

<!-- - Hardware: orion, 2× RTX 3090 (Ampere sm_86), NVLink=0 (PHB topology) -->
<!-- - Interconnect: PCIe host bridge (PHB topology) — P2P disabled, all-reduce crosses PCIe -->
<!-- - `nvidia-smi topo -m` (PHB state): GPU0 --PHB-- GPU1, no NVLink P2P between GPUs -->
<!-- - NCCL all-reduce on TP=2 goes over PCIe → adds ~0.5–1s latency floor per prefill -->
<!-- - This is the constraint everything else in this post lives under -->

<!-- SECTION 2: Sweep timeline -->

## The Six Pre-NVLink Sweeps

<!-- Chronology of the PCIe-era runs. All on `NVLink=0`. -->

| # | Date | Sweep | Models | Key finding |
|---|---|---|---|---|
| 1 | 2026-06-23 | TP=2 anchor | 8 models | qwen3-coder-30b winner (150.6 tok/s, 256K ctx) |
| 2 | 2026-06-25 | Ampere salvage | glm47-flash, gpt-oss | fp8e4nv fix → GLM viable (110 tok/s), gpt-oss dead (11 tok/s) |
| 3 | 2026-06-28 | Concurrency scaling | main models | c4 aggregate throughput reported |
| 4 | 2026-06-29 | GLM single-GPU | glm47-flash | Fits 1 GPU (107 tok/s, 89K ctx) |
| 5 | 2026-06-29 | gpt-oss nightly | gpt-oss-20b | Needs newer image; original runs eager-only at ~11 tok/s |
| 6 | 2026-06-29 | qwen36-27b TP=2 | qwen36-27b | TTFT floor discovery (~4.2s at TP=2, dominated by PCIe) |

<!-- Also run: qwen36-27b single-GPU (~40 tok/s, ~3.7s TTFT, 32K ctx ceiling) -->
<!-- Also run: 60B-REAM retest (confirmed 118 tok/s, 256K ctx — prior OOM was transient) -->

<!-- SECTION 3: The winning tier (models that cleared the 2500ms budget) -->

## The Winning Tier: Models Under 2500ms TTFT at TP=2

<!-- Ranked by decode tok/s, single-user (concurrency 1, input=4096, output=512) -->

| Model | Decode tok/s | TTFT p50 ms | GPUs | Max usable ctx | Type |
|---|---:|---:|---:|---:|---|
| qwen3-coder-30b | **152.94** | 629 | 2 | 256K | MoE coding specialist |
| qwen36-35b-a3b | **136.31** | 990 | 2 | 192K | MoE multimodal |
| qwen3-coder-next-60b-ream | **118.61** | 1203 | 2 | 256K | MoE coding specialist |
| glm47-flash (TP=2) | **110.95** | 1181 | 2 | 192K | MoE coding agent |
| glm47-flash (1 GPU) | **107.05** | 795 | 1 | 89K | MoE coding agent |
| gpt-oss-20b-nightly | **64.81** | 855 | 2 | 128K | Dense (nightly image) |

<!-- Note: glm47-flash single-GPU figure from salvage run; it failed at TP=2 in the 06-23 sweep. -->
<!-- Note: qwen36-35b-a3b is multimodal (vision tower active); `--language-model-only` is Sweep C. -->

<!-- SECTION 4: The models that failed the budget -->

## Models That Failed the TTFT Budget

<!-- These models produced valid configs (decode tok/s numbers are real) but their TTFT exceeded 2500 ms at the best configuration. They are unusable for single-user agentic coding on PCIe TP=2. -->

| Model | Best decode tok/s | Best TTFT p50 ms | GPUs | Why it failed |
|---|---:|---:|---:|---|
| qwen36-27b (TP=2) | ~59.7 | ~4215 | 2 | NCCL all-reduce over PCIe dominates every prefill |
| qwen36-27b (1 GPU) | ~40 | ~3700 | 1 | Dense model, not coding-specialized; TTFT still over budget |
| devstral-24b-gptq | 54.90 | 3239 | 2 | General multimodal assistant; TTFT over budget |
| devstral-24b-fp8 | 53.43 | 3131 | 2 | Same as GPTQ variant; FP8-native weights |
| gpt-oss-20b (original) | 11.11 | — | 2 | `--enforce-eager` required on Ampere → ~14× slower than Qwen winners |
| qwen3-coder-next-80b | — | — | 2 | OOM in all attempts — too large for 2× 24 GiB |

<!-- SECTION 5: The PCIe TTFT floor insight -->

## The PCIe TTFT Floor

<!-- The most important finding from the PCIe sweeps: qwen36-27b at TP=2 had TTFT **flat at ~4210–4227ms across every parameter combination** (utilization, length, seqs, batch size). No sweep knob changed it. -->

<!-- - The TTFT floor is not prefill compute — it's the NCCL all-reduce crossing PCIe -->
<!-- - TP=2 makes dense models **worse** on TTFT than single-GPU (4.2s TP=2 vs 3.7s single) -->
<!-- - MoE models don't show this penalty because only ~3B params are active per token — the all-reduce payload is smaller -->
<!-- - This means: on PCIe, TP=2 is only worth it for MoE models (context gain without TTFT penalty) -->
<!-- - The fix is hardware: NVLink bridge moves the all-reduce off PCIe -->

<!-- SECTION 6: Ampere-specific compatibility -->

## Ampere (sm_86) Compatibility Gotchas

<!-- Two models required per-model overrides to produce even a single valid config: -->

| Model | Override | Why |
|---|---|---|
| glm47-flash | `--kv-cache-dtype auto` | `fp8e4nv` unsupported in grouped-attention KV kernel on sm_86 |
| gpt-oss-20b (original) | `--enforce-eager --kv-cache-dtype auto` | (1) torch.compile/Inductor autotune failure on MXFP4 MoE kernel; (2) `fp8e4nv` in `reshape_and_cache_kernel_flash` |

<!-- - The overrides ride on per-model `M_EXTRA` in `vllm-sweep.sh` (argparse last-occurrence semantics) -->
<!-- - gpt-oss-20b with `--enforce-eager` is functionally correct but ~11 tok/s — `--enforce-eager` kills CUDA graphs + torch.compile -->
<!-- - gpt-oss-20b is viable on nightly image (64.81 tok/s) because the newer vLLM build fixes the Ampere kernel path -->

<!-- SECTION 7: Concurrency scaling (PCIe) -->

## Concurrency Scaling: What Happens When Two Agents Ask at Once

<!-- Aggregate decode throughput at concurrency 1 → 2 → 4. Each model at its winning config. -->

| Model | c1 decode tok/s | c2 agg tok/s | c4 agg tok/s | Note |
|---|---:|---:|---:|---|
| qwen36-35b-a3b | 136 | **271** | **542** | Highest aggregate; DeltaNet produces 1.88M-token KV pool |
| qwen3-coder-30b | 150 | **253** | **399** | Best single-user + strong batching |
| qwen3-coder-next-60b-ream | 119 | **191** | **368** | Confirmed in retest |
| glm47-flash (TP=2) | 98 | — | — | Crashes under sustained concurrent load |
| glm47-flash (1 GPU) | 100 | — | — | Same crash behaviour |

<!-- Key takeaway: GLM crashes at concurrency > 1 (likely `--enable-expert-parallel` + FlashInfer interaction). Use Qwen models for multi-agent workloads on a single vLLM instance. -->

<!-- SECTION 8: Context ceiling (PCIe) -->

## Maximum Usable Context: What Each Model Fits

<!-- Largest `max-model-len` that produced a successful `ok` config on PCIe TP=2. -->

| Model | Max usable ctx | KV cache tokens | Decode tok/s at ceiling | GPUs |
|---|---:|---:|---:|---:|
| qwen3-coder-30b | **256K** | 535632 | 150.04 | 2 |
| qwen3-coder-next-60b-ream | **256K** | 645438 | 118.49 | 2 |
| qwen36-35b-a3b | 192K | 1877606 | 135.90 | 2 |
| glm47-flash (TP=2) | 192K | 236768 | 99.59 | 2 |
| qwen36-27b (TP=2) | 192K | 801326 | 59.68 | 2 |
| devstral-24b-gptq | 128K | 199952 | 54.62 | 2 |
| gpt-oss-20b-nightly | 128K | 1101438 | 42.96 | 2 |
| glm47-flash (1 GPU) | 89K | 120448 | 82.92 | 1 |
| qwen36-27b (1 GPU) | 32K | 70390 | 39.84 | 1 |

<!-- Key insight: context length costs zero throughput at concurrency 1. Decode stays flat from 32K to ceiling. Larger `max-model-len` only reduces KV headroom for batching — irrelevant for single-user coding. -->

<!-- SECTION 9: Pre-NVLink production recommendations -->

## Pre-NVLink: What You'd Actually Deploy

<!-- Based on all PCIe sweeps, the llama-swap roster would look like: -->

**Tier 1 — Daily driver:**
- `qwen3-coder-30b` (TP=2, 153 tok/s, 256K ctx, non-thinking mode)
- `qwen36-35b-a3b` (TP=2, 136 tok/s, 192K ctx, multimodal)

**Tier 2 — Diversity / fallback:**
- `glm47-flash` (single GPU, 107 tok/s, 89K ctx) — co-locate with qwen30b on GPU 1
- `qwen3-coder-next-60b-ream` (TP=2, 119 tok/s, 256K ctx) — quality upgrade, slower
- `gpt-oss-20b-nightly` (TP=2, 65 tok/s, 128K ctx) — requires nightly image

**Tier 3 — Skip on PCIe:**
- devstral-24b (TTFT over budget at both 3.1–3.2s)
- qwen36-27b (TTFT over budget, not a coding specialist)
- gpt-oss-20b original image (11 tok/s eager-only)
- qwen3-coder-next-80b (OOM)

<!-- SECTION 10: The arc into the next post -->

## What Changes with NVLink

<!-- The PCIe verdict: dense models (devstral, qwen36-27b) are dead at TP=2 because NCCL all-reduce crosses PCIe. MoE models are fine because their active parameter count is tiny. -->
<!-- On 2026-07-11, a NVLink bridge was installed. `nvidia-smi topo -m` went from `PHB`/PCIe to `NV3` (3-link bond). -->
<!-- The question: does this fix the dense-model TTFT problem? -->
<!-- See [Post 3: Post-NVLink results](posts/vllm-sweep-post-nvlink.md) — the dense models cross under budget, the verdict flips, and TP=2 becomes the default across the board. -->
