---
title: "Benchmarking vLLM on 2× RTX 3090: Setup and Aim"
date: 2026-07-16
description: "Hardware, software, and methodology for a systematic TP=2 coding model sweep on an Ampere dual-GPU rig — what the sweep does, how it works, and what 'best config' actually means."
section: blog
---

With the release of Anthropic's Opus 4.6 model earlier this year (2026), I came to the realisation that code development has changed forever. I wasn't sure what the impact would be, but it was clear that I'd have to rethink my position on LLMs and their impact on my life. I was a reluctant convert at that point, but a convert nonetheless. The more I dug into it (and the more I hit the five-hour Claude session limits) the more I realised that the only real limit to producing endless reams of code in the LLM era was access to power and GPUs. With those two things in place, and a proper (open) model, you can produce code at the cost of kilowatts.

Since I live somewhere with abundant sunshine and solar to match, that was power sorted, and all I needed was to get my hands on some GPUs (which were already becoming scarcer as more and more people came to the same conclusion I did). Either way, a friend hooked me up with two 3090s (after a lot of research to determine the most tokens for the least bucks) and a sweet rig to run them in, and the experimenting started.

## The Machine

Before I could get to the complexities of actually running the models, I had to get the hardware. The build was centred on the GPUs, with the rest of the build focusing on ensuring the cards have enough compute and memory to operate correctly. The two RTX 3090s (24 GiB each, 48 GiB combined) were central to the build, with everything else designed to support them. Lots of fans, a good CPU, lots of RAM. I've got a NAS running at home, so storage was left to it. At some point I had to add another drive, since experimenting with models requires a LOT of storage.

### The specifics

| Component | Specification |
|---|---|
| Host | orion |
| GPU | 2× NVIDIA GeForce RTX 3090, 24 GiB VRAM each — 48 GiB combined, split across two cards |
| Architecture | Ampere, sm_86 |
| Driver / CUDA | 595.71.05 / CUDA 13.2 |
| VBIOS | 94.02.42.00.A7 |
| CPU | AMD Ryzen 9 3900 — 12 cores / 24 threads, 4.36 GHz boost |
| RAM | 62 GiB DDR4 — ~45 GiB available during sweep runs |
| Storage | Crucial MX500 500 GB SATA SSD — 296 GB free |
| Interconnect | PCIe host bridge — PHB → NVLink bridge — NV3, 3-link bond — installed 2026-07-11 |

## Context is the name of the game

If you've done any kind of work with Claude Code or any coding agent, you'll know that context is everything. The more context you give, and the better the quality and structure of the context, the better the results. The challenge with running models locally is providing a big enough context for coding tasks to be useful. With the machine set up and ready, I wanted to optimize my setup to provide the best quality models with the biggest possible context. Both of these require space in your GPUs, so there's a fine balance between model and context size.

On top of that there are various flags and capabilities that affect performance and memory requirements. A further challenge I had was that even though I had 48 GiB of VRAM in total, it was split over two cards. You can load a single model over both cards, but then you have to use the normal PCI lanes on the motherboard to let the two GPUs speak to each other. This takes up a lot of compute, and isn't the most effective way to do it. More on that later. In short, it was just another variable to test against.

## The Sweep Orchestrator: `vllm-sweep.sh`

Between the hardware, the context splits and the multitude of models and options, the permutations quickly stacked up, and I had to find a way to automate the testing of all the model / parameter / context permutations. Enter the sweep. The sweep script runs through a predefined set of model and option permutations, using vLLM as a model delivery method, iterating through larger and larger contexts, testing first if the model actually loads, and then testing the performance parameters, recording the results all the way.

## The Six Sweep Stages

Each sweep stage below performed a specific function and / or test to ensure the accuracy and completeness of the tests.

**S0 — Anchor:** Sets a baseline with a single config — util 0.90, max-model-len at 32K, max-num-seqs at 1, batch-size at 512 — and confirms the model actually loads and produces sensible numbers. Without this, everything else is just guessing.

**S1 — Batched:** Scales the batch-size up from 512 to 8192 at S0's baseline. Bigger batches let the GPU chew through more tokens in parallel, but if you push it too hard you waste VRAM on overhead. This stage finds the sweet spot.

**S2 — Seqs:** Does the same thing for max-num-seqs — tries 1, 2, and 4. It's similar to batch-size but not quite the same thing: batch-size controls how many tokens are prefilling at once, while max-num-seqs controls how many independent requests can run at the same time. Both matter, but in different ways.

**S3 — Length:** Pushes max-model-len up from 32K to larger values, checking whether the model still loads and how performance changes at each step. This is where you learn whether a model can handle a decent context window or whether it folds at the first sign of strain.

**S4 — Util:** Varies GPU memory utilization around the S0 anchor — tries 0.85, 0.90, and 0.95. Higher utilization gives you more KV cache headroom for context, but pushes you closer to OOM. Lower utilization gives you safety margin at the cost of context ceiling. You have to find the balance.

**S5 — LM-only:** For the multimodal models — the ones with vision towers — this toggles the `--language-model-only` flag. Disabling the vision tower frees up VRAM — I expected 20-40% context headroom — and it's worth testing because the vision tower isn't needed for coding tasks anyway.

**S6 — Context ceiling:** Cranks max-model-len up until the model chokes — first failure, whether it's an OOM or a timeout. This gives you the absolute maximum usable context for each model, which is the number you care about when the context actually matters.

## How the Winner Is Chosen

Coding automation requires a certain amount of tokens per second to be interactive, as well as a fairly low time to first token. Tokens per second (TPS) is how fast the model generates tokens (which correlates with generated words). Time to first token (TTFT) measures how long it takes for the model to load the prompt and then run inference before it starts generating the tokens. You want a low TTFT and a high TPS, otherwise the user will just sit around waiting for the model to respond. The sweep was looking for models that had a decent TPS and TTFT, as well as a proper context size. Having the ability to run concurrent requests would also allow me to run multiple agents or subagents at the same time, providing even more efficiencies. The models that could provide all of that with predefined parameters were declared winners that I could consider usable going forward.

<!-- - Winner = highest decode tok/s whose median TTFT (input=4096 tokens, concurrency=1) is under `TTFT_BUDGET_MS` (default 2500 ms) -->
<!-- - Ties broken toward larger `max usable context` -->
<!-- - The TTFT budget is a prefill-latency gate — a model that serves fast but takes 5 seconds to start answering is useless for agentic coding -->
<!-- - Decode speed is measured at concurrency 1 (single-user coding) — concurrency scaling is reported separately -->

## Models in the Sweep

I tried out a range of models, all around the 30B size, with a few notable exceptions where I tried to push the memory limits. The table below shows the models and their outcomes.

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

The results made for some interesting reading. MoE models dominated (they fit bigger contexts and handled TP=2 better than dense models on PCIe). But there were hard limits too: an 80B model simply couldn't fit, and several dense models hit TTFT floors that made them useless for coding. The full story of what those numbers mean (and how an NVLink bridge flipped the verdict) is in the next two posts.

## External Resources

**Models on Hugging Face**

These are the actual model IDs loaded by `llama-swap` on orion (the exact quantised builds used in production and sweeps).

| Model | Hugging Face |
|---|---|
| qwen3-coder-30b | [cyankiwi/Qwen3-Coder-30B-A3B-Instruct-AWQ-4bit](https://huggingface.co/cyankiwi/Qwen3-Coder-30B-A3B-Instruct-AWQ-4bit) |
| qwen36-35b-a3b | [cyankiwi/Qwen3.6-35B-A3B-AWQ-4bit](https://huggingface.co/cyankiwi/Qwen3.6-35B-A3B-AWQ-4bit) |
| qwen3-coder-next-60b-ream | [cyankiwi/Qwen3-Coder-Next-REAM-AWQ-4bit](https://huggingface.co/cyankiwi/Qwen3-Coder-Next-REAM-AWQ-4bit) |
| glm47-flash | [cyankiwi/GLM-4.7-Flash-REAP-23B-A3B-AWQ-4bit](https://huggingface.co/cyankiwi/GLM-4.7-Flash-REAP-23B-A3B-AWQ-4bit) |
| qwen36-27b | [cyankiwi/Qwen3.6-27B-AWQ-INT4](https://huggingface.co/cyankiwi/Qwen3.6-27B-AWQ-INT4) |
| gpt-oss-20b | [openai/gpt-oss-20b](https://huggingface.co/openai/gpt-oss-20b) |
| devstral-24b | [mistralai/Devstral-Small-2507](https://huggingface.co/mistralai/Devstral-Small-2507) (sweep-only, not deployed) |
| qwen3-coder-next-80b | [Qwen/Qwen3-Coder-Next](https://huggingface.co/Qwen/Qwen3-Coder-Next) (OOMs on 2× 24 GB, never deployed) |

**Documentation**

- [vLLM documentation](https://docs.vllm.ai/) — Docker images, benchmark CLI, tensor parallelism, `--kv-cache-dtype`
- [NCCL documentation](https://docs.nvidia.com/deeplearning/nccl/user-guide/) — all-reduce, P2P, multi-GPU communication
- [CUDA Toolkit 13.2](https://developer.nvidia.com/cuda-toolkit) — CUDA runtime used by the `vllm/vllm-openai:latest` Docker image
- [NVIDIA Ampere architecture](https://www.nvidia.com/en-us/geforce/graphics-cards/30-series/rtx-3090/) — sm_86 compute capability, `fp8e4nv` support notes

**Community**

- [3090 Club](https://github.com/noonghunna/club-3090) — community recipes for serving LLMs on RTX 3090/4090/5090; multi-engine (vLLM, llama.cpp, SGLang); OpenAI-compatible API configs

**Tools**

- [Sweep script](/vllm-sweep.sh) — the full `vllm-sweep.sh` orchestrator; 1131 lines, runnable standalone
