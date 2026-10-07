---
title: "Naive Bayes vs Decider: [TODO: working title]"
date: 2026-10-07
description: "[TODO: one sentence — the headline result and why it matters for anyone choosing between a classic classifier and an LLM.]"
section: blog
draft: true
---

<!--
SCAFFOLD — notes in HTML comments are for drafting and won't render.
Scope: highlight the results only; the full analysis gets its own post (link below).
Focus: the WHY behind the results and what they imply.
Content axes: AI Architecture (model selection, token/power economics) and
AI Decision-Making (when the LLM is the wrong tool).
-->

<!--
HOOK (1–2 paragraphs)
- The question we set out to answer, in plain terms.
- The one-line punchline: [TODO: e.g. "NB matched/beat Decider on X while using Y× less power"].
- Why an SME tech lead should care before reading further.
-->

## The setup, briefly

<!--
Just enough context to read the results — no methodology deep-dive (that's the full analysis post).
- What is Decider? [TODO: Q1]
- What task were both classifying? [TODO: Q2]
- Dataset: size, time span, how it was split. [TODO: Q3]
- Hardware each ran on. [TODO: Q4]
-->

For the full methodology, numbers and code, see [TODO: link to full analysis post].

## The results

<!--
Headline numbers only. Suggested table — keep it to the 3–5 metrics that drive the argument.
-->

| Metric | Naive Bayes | Decider |
| --- | --- | --- |
| Accuracy (initial) | TODO | TODO |
| Accuracy (end of period) | TODO | TODO |
| Power per [TODO: 1k classifications?] | TODO | TODO |
| Latency per item | TODO | TODO |
| Cost per [TODO unit] | TODO | TODO |

<!--
One short paragraph per surprising result. Resist explaining "why" here — that's the next section.
-->

## Why the power gap is so big

<!--
The mechanics, not just the ratio.
- NB: counting and a lookup — a few multiplications per token, runs on a CPU core.
- Decider: [TODO: model size, GPU, tokens processed per item, idle draw?]
- Is the gap per-inference, or does fixed overhead (GPU idle, model load) dominate? [TODO: Q6]
- Put it in real terms: kWh/month at our volume, rand cost, solar budget, GPU you can't use for anything else.
-->

## Accuracy decays over time

<!--
The second big finding: [TODO: Q7 — which model lost accuracy, and by how much?]
- Show the shape of the decline (chart from the full analysis? [TODO]).
- Cause: concept/data drift — [TODO: what changed in the data?]
- Retraining cost: NB retrains in [seconds?] on new labels; Decider needs [re-prompting / fine-tuning / new examples?].
- The uncomfortable point: a model that's "smarter" on day one can be the worse model on day 90 if it's expensive to keep current.
-->

## What this means for your architecture

<!--
The implications section — the reason the post exists. Candidate points (keep the ones that hold up):
1. Start with the boring baseline. If NB gets you to [X]%, the LLM has to earn the remaining gap.
2. Price the whole lifecycle, not the first benchmark: power + retraining + monitoring.
3. Drift monitoring is not optional, whichever model you pick — build the feedback loop first.
4. Hybrid: NB as the first pass, LLM only on low-confidence items? [TODO: Q9 — did we test this?]
5. Where the LLM still wins: [TODO: be fair — what did Decider do better?]
-->

## Wrapping up

<!--
- Restate the decision rule in one sentence.
- Pointer to the full analysis post.
- Optional: what's next (hybrid test, longer time window, other models).
-->
