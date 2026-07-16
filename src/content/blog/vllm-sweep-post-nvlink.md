---
title: "Benchmarking vLLM on 2× RTX 3090 — Post-NVLink: The Verdict Flips"
date: 2026-07-16
description: "Installing an NVLink bridge on 2× RTX 3090 and re-running the sweep — dense models cross the 2500ms TTFT budget, and TP=2 becomes the default across the board."
draft: true
---

<!-- SECTION 1: The hardware change -->

## The NVLink Bridge

<!-- - Date: 2026-07-11 (postfix NV3) -->
<!-- - Verification: `nvidia-smi topo -m` changed from `PHB`/PCIe to `NV3` (3-link bond) -->
<!-- - What NVLink gives: low-latency path for NCCL all-reduce between GPUs -->
<!-- - What NVLink does NOT give: extra VRAM, extra KV pool, bigger context ceiling -->
<!-- - NVLink adds bandwidth, not memory — context ceilings stay the same -->

<!-- SECTION 2: How to verify NVLink is working -->

## Verifying NVLink in vLLM

<!-- - vLLM's custom all-reduce kernel still crashes on sm_86 (`custom_all_reduce.cuh:455`) → `--disable-custom-all-reduce` stays on -->
<!-- - `detect_nvlink()` in `vllm-sweep.sh` now passes `--disable-custom-all-reduce` and forces `NCCL_P2P_DISABLE=1` **only when NVLink is absent** -->
<!-- - With NVLink present: custom kernel off, but NCCL runs its all-reduce over the NVLink bridge -->
<!-- - Verification: booting produces `engine HEALTHY ~100s`, smoke config shows 168 tok/s / 409ms TTFT (vs ~4.2s PCIe) -->
<!-- - If NVLink is absent, NCCL falls back to PCIe with `NCCL_P2P_DISABLE=1` → the old penalty returns -->

<!-- SECTION 3: The NVLink sweep -->

## The Post-NVLink Sweep

<!-- Fresh TP=2 sweep after bridge install. Same roster, same sweep stages (S0–S6), same winner criteria. -->
<!-- Results in: `20260711-123840.md` (main sweep) + `20260711-184925-qwen36-27b.md` (dense-model verdict test) -->

<!-- SECTION 4: Axis 1 — TTFT (the headline) -->

## Axis 1: TTFT — Halved Across the Board

<!-- Direct PCIe (NVLink=0) vs NVLink (NVLink=1) comparison. All at TP=2. Median TTFT, best config. -->

| Model | PCIe TTFT | NVLink TTFT | Δ | Budget (2500 ms) |
|---|---:|---:|---:|---:|
| qwen3-coder-30b | 1112 ms | **415 ms** | −63% | ✅ → ✅ |
| qwen36-35b-a3b | 997 ms | **412 ms** | −59% | ✅ → ✅ |
| qwen3-coder-next-60b-ream | 1203 ms | **529 ms** | −56% | ✅ → ✅ |
| glm47-flash (†) | ~1181 ms | **511 ms** | −57% | ✅ → ✅ |
| devstral-24b-gptq | 3235 ms | **2013 ms** | −38% | ❌ → ✅ |
| qwen36-27b | 4222 ms | **2199 ms** | −48% | ❌ → ✅ |

<!-- The dense models are the headline: both were **over budget and unusable** on PCIe, and both drop **under 2500 ms** on NVLink. This overturns the pre-NVLink verdict that "TP=2 hurts dense models." -->
<!-- († glm47-flash PCIe figure is from single-GPU salvage run — the comparison is single-GPU-PCIe vs TP2-NVLink, not a clean like-for-like. Direction is right, magnitude is soft.) -->

<!-- SECTION 5: Axis 2 — Decode (modest) -->

## Axis 2: Decode — Uniformly Small Gains

<!-- The thing NVLink does not fix is decode throughput. Decode emits one token at a time, so its all-reduces are tiny and were never PCIe-bound. -->

| Model | PCIe tok/s | NVLink tok/s | Δ |
|---|---:|---:|---:|
| qwen3-coder-30b | 150.6 | **167.7** | +11.3% |
| qwen36-35b-a3b | 136.3 | **148.2** | +8.7% |
| qwen3-coder-next-60b-ream | 118.6 | **128.0** | +7.9% |
| glm47-flash (†) | ~111.0 | **117.5** | +5.9% |
| qwen36-27b | 59.8 | **62.7** | +4.8% |
| devstral-24b-gptq | 54.9 | 54.2 | −1.3% (flat) |

<!-- Uniformly single-digit to low-double-digit. MoE/coding models gain a bit more. devstral is within noise. Decode was never the thing NVLink fixes. -->

<!-- SECTION 6: Axis 3 — Max Context (no change) -->

## Axis 3: Maximum Usable Context — The Same Ceilings

<!-- NVLink changes neither VRAM nor the KV-pool math, so every model lands on the same ceiling it hit on PCIe. -->

| Model | PCIe max ctx | NVLink max ctx | Δ |
|---|---:|---:|---:|
| qwen3-coder-30b | 256K | 256K | = |
| qwen3-coder-next-60b-ream | 256K | 256K | = |
| qwen36-35b-a3b | 192K | 192K | = |
| qwen36-27b | 192K | 192K | = |
| glm47-flash (†) | — | 192K | new (ran at TP=2 first time) |
| devstral-24b-gptq | 128K | 32K ‡ | run artifact (timeout stopped probe early) |

<!-- NVLink's value at long context is "same window, more tok/s" — e.g. qwen3-coder-30b serves its full 256K context ~10% faster. -->
<!-- (‡ devstral 32K ceiling is a run artifact — the 64K launch hit `READY_TIMEOUT` and stopped the probe early. Devstral fits 128K on this hardware; NVLink didn't shrink it.) -->

<!-- SECTION 7: The overturned verdict -->

## The Verdict Flips

<!-- Pre-NVLink guidance: "dense models must run single-GPU; use TP=2 only for KV headroom on MoE models." -->
<!-- Post-NVLink guidance: **TP=2 is the better default across the board.** -->
<!-- Dense coding models (devstral, qwen36-27b) are viable single-user for the first time. MoE models get faster prefill and a bit more throughput. Long-context serving keeps the same window at higher tok/s. -->
<!-- qwen3-coder-next-80b still OOMs on 2×24 GB — pure VRAM capacity, NVLink is irrelevant to it. -->

<!-- SECTION 8: Post-NVLink production roster -->

## Post-NVLink: What You'd Actually Deploy

<!-- The same three-tier structure, updated: -->

**Tier 1 — Daily driver (unchanged):**
- `qwen3-coder-30b` (TP=2, 168 tok/s, 256K ctx, non-thinking mode)
- `qwen36-35b-a3b` (TP=2, 148 tok/s, 192K ctx, multimodal)

**Tier 2 — Diversity / fallback (one new member):**
- `glm47-flash` (TP=2 now possible: 118 tok/s, 192K ctx — first run at TP=2)
- `glm47-flash` (single GPU, 107 tok/s, 89K ctx) — still co-locatable
- `qwen3-coder-next-60b-ream` (TP=2, 128 tok/s, 256K ctx)
- `gpt-oss-20b-nightly` (TP=2, 65 tok/s, 128K ctx)

**Tier 3 — Previously dead, now alive:**
- devstral-24b (TP=2, TTFT now 2013ms — under budget!) — still general assistant, not coding specialist
- qwen36-27b (TP=2, TTFT now 2199ms — under budget!) — still general-purpose, but now runnable

**Tier 4 — Still dead:**
- qwen3-coder-next-80b (OOM on 2×24 GB — raw capacity, not interconnect)

<!-- SECTION 9: The physics, in one paragraph -->

## Why the Three Axes Behave Differently

<!-- - **TTFT (big win):** Each prefill does a full-tensor all-reduce to recombine two GPUs' partial results. On PCIe that crosses the host bridge and dominates TTFT. NVLink gives NCCL a low-latency path — the latency floor collapses. -->
<!-- - **Decode tok/s (small win):** Decode emits one token at a time, so its all-reduces are tiny and were never PCIe-bound. The few-percent gain is second-order (less contention, better overlap), not a step change. -->
<!-- - **Max context (no change):** The usable ceiling is set by how much KV cache fits in 2× 24 GB. NVLink changes neither VRAM nor the KV-pool math. -->

<!-- SECTION 10: Open questions -->

## What's Still Open

<!-- - **Devstral-24B with `--language-model-only`** — both Devstral variants were benchmarked with the vision tower active. Disabling it could recover 20–40% KV headroom. Low priority. -->
<!-- - **GLM concurrency fix** — crashes under concurrent load (c2+ bench fails). Likely `--enable-expert-parallel` + FlashInfer interaction. A targeted retest might unlock concurrent serving. -->
<!-- - **Two-model co-location** — `qwen3-coder-30b` (GPU 0) + `glm47-flash` (GPU 1) is now confirmed feasible at TP=2 for GLM. The llama-swap config change is a separate manual step. -->
<!-- - **Adopt winning config** — `qwen3-coder-30b` at `util=0.95, max-model-len=262144` is the clear production winner. Requires a manual llama-swap config change (out of scope for the sweep tool). -->
<!-- - **Sweep A (Concurrency scaling)** — the highest-value follow-up per `followup-sweeps-plan.md`. Surfaces c1→c2→c4 aggregate throughput for the four viable coders. Needs 3 functions edited in `vllm-sweep.sh`. -->

<!-- SECTION 11: The arc -->

## TL;DR

<!-- A $3K dual-RTX-3090 rig with an NVLink bridge and vLLM can serve production-quality coding models. -->
<!-- qwen3-coder-30b at ~168 tok/s, 256K context, non-thinking mode. -->
<!-- NVLink fixes the TTFT problem (PCIe was the bottleneck, not the model). -->
<!-- TP=2 is the default. Dense models that were dead on PCIe are now viable. -->
<!-- Context ceilings are set by VRAM, not interconnect. Decode gains are modest. TTFT is the story. -->
<!-- The sweep is report-only — adopting these configs into llama-swap is a separate manual step. -->
