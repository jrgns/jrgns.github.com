---
title: "[TODO: title] Naive Bayes vs a 2B Decider Model"
date: 2026-10-07
description: "A 2B-parameter decision model classifies research abstracts at 72% with zero examples. Naive Bayes needs about 500 labelled examples to match it — and then does the job for roughly 1/5,600th of the energy."
section: blog
draft: true
---

<!--
SCAFFOLD — notes in HTML comments are for drafting and won't render.

Scope: highlight results only. The full report (methodology, contamination check,
every table) is published separately and linked below. This post is about the WHY
and the IMPLICATIONS.

Content axes: AI Architecture (model selection, energy/latency economics) and
AI Decision-Making (when the LLM is the wrong tool — and when it isn't).

Source: "Naive Bayes vs Decider 2B" benchmark report (artifact EKbnKBEKhLgVQezuvxtfna).
-->

<!--
HOOK (1–2 paragraphs)
- AWS released Strands Decider: a 2B model built to make classification-style decisions
  inside agents, zero-shot. [TODO: Q1 — what prompted you to test it?]
- The question: how many labelled examples does a boring, tuned scikit-learn Naive Bayes
  need before it matches Decider — and what does each cost to run?
- Punchline: about 70–100 per class. After that NB is as accurate or better, ~5,600×
  cheaper in energy and ~200× faster per item.
-->

## What we tested

<!--
Keep this to a short paragraph plus a link. Just enough to read the results.
- Task: Web of Science WOS-46985, level-1 labels — 7 research fields (Computer Science,
  Electrical, Psychology, Mechanical, Civil, Medical, Biochemistry). ~200-word abstracts.
- Chosen because it's NOT in Decider's training data (the usual suspects — AG News,
  DBpedia, Yahoo Answers, 20 Newsgroups — all are). 254 items overlapping arXiv were removed.
- Decider: zero-shot, only the label names and descriptions. Best of three wordings, picked on dev.
- NB: Multinomial/Complement NB, tuned with CV, trained on 1–1,000 labelled examples per class.
- Same 9,996 test items for both. One RTX 3090 + Ryzen 9 3900, energy from hardware counters.
-->

The full methodology, contamination check and every table are in the [full report](TODO-link).

## The results

| | Naive Bayes | Decider 2B |
| --- | --- | --- |
| Labelled examples needed | ~70 per class to tie (490), 100 to win clearly (700) | none (label wording only) |
| Accuracy at 100 per class | 0.748 | 0.721 (zero-shot) |
| Accuracy at 1,000 per class | 0.800 | 0.721 |
| Energy per 1,000 predictions | 1.47 mWh | 8.22 Wh (~5,600×) |
| Latency per item (p50) | 0.5 ms on one CPU thread | 96 ms on a GPU (~194×) |
| Whole test set (9,996 items) | 1.4 s | 17 min |
| Training cost | 86 mWh incl. full tuning ≈ 10 Decider predictions | sunk (AWS's) |
| Calibration (ECE, lower is better) | 0.21 | 0.04 |
| Flip rate if option order changes | n/a | 16.7% |

<!--
One short paragraph per result that surprised you. Save the "why" for the next sections.
Candidates:
- How fast NB catches up: 20/class → 0.62, 50/class → 0.70, 70/class → tie.
- The energy break-even: tuning + training NB costs less than 10 Decider calls.
- Decider is genuinely better calibrated — its confidence means something.
-->

## Why the gap is so big

<!--
The mechanics, not just the ratio.
- NB: count words per class once, then classifying = a sparse dot product and an argmax.
  Sub-millisecond on one CPU thread, no GPU at all.
- Decider: a 2B-parameter forward pass over ~260+ tokens of abstract PLUS the rendered
  prompt with 7 options and descriptions — for every single item. ~30 J per prediction.
- The generalist tax: Decider carries the machinery to decide anything; NB only knows
  these 7 classes. You pay for generality on every call.
- Fixed costs come on top: model load (15 s) and warmup (58 s) excluded from the headline,
  and a GPU that idles at ~25 W whether or not anything is classified.

!! See question Q4 — the ratio is huge, but in absolute terms 8.22 Wh per 1,000 is
   ~8 kWh per MILLION predictions. Decide whether the argument is energy, or
   latency/throughput/hardware (~10 items/s on a 3090 = ~860k/day ceiling).
-->

## [TODO: "accuracy over time" section — see Q2]

<!--
CONFLICT: the report has no time-based/drift experiment. Options for this section:

(a) Prior shift as a stand-in for drift. NB trained on the whole imbalanced pool
    (34,733 items, 37% Medical) scored 0.735 — 6.5 points WORSE than NB on a balanced
    7,000. Medical recall rose to 0.88, Mechanical fell to 0.42. Lesson: NB learns your
    class mix; when production's mix moves, accuracy moves with it. Decider has no
    learned prior, so it doesn't suffer this — but it can't improve either.
(b) Retraining economics: NB's refit costs < 1 Decider prediction (1.3 mWh) and 0.16 s,
    so retraining nightly on fresh labels is free. Decider's only lever is rewording.
(c) Run a real time-split experiment first and write this section afterwards.
-->

## What this means for your architecture

<!--
The section the post exists for. Keep the points that hold up after Q&A:
1. Zero-shot is a starting point, not an architecture. Decider is how you ship on day one
   with no labels; its predictions + human corrections become NB's training set.
   ~500–700 labels is days of work, not months.
2. Price the labels, not just the kWh. The report doesn't count labelling cost — that's
   the real trade: Decider buys you out of labelling, NB buys you out of GPUs.
3. Calibration matters for routing. Decider's confidence is trustworthy (ECE 0.04); NB's
   isn't (ComplementNB doesn't produce real probabilities). Hybrid: NB first, escalate
   low-confidence items to Decider? [TODO: Q6]
4. Prompt fragility is an operational risk. Shuffling option order flips 1 in 6
   predictions; listing Medical first biases towards Medical. Pin the prompt like you'd
   pin a dependency. (NB is byte-for-byte repeatable.)
5. Ceiling: Decider is frozen at 0.72 on this task; NB keeps climbing to 0.80 with data.
-->

## Caveats

<!--
Short and honest — credibility comes from this.
- One dataset, one 7-class task, one GPU.
- Decider's label wording was written from the WOS taxonomy (a user without it scored ~0.66 on dev).
- Qwen3.5-2B-Base pre-training data is unknown; WOS could be in it (would favour Decider).
- Energy is GPU board + CPU package; no wall meter, no DRAM.
-->

## Wrapping up

<!--
- The decision rule in one sentence.
- Link to the full report.
- What's next: [TODO: Q7]
-->
