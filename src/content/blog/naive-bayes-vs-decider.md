---
title: "LLMs Are the Stopgap: Naive Bayes vs a 2B Decider Model"
date: 2026-10-07
description: "A purpose-built 2B model classifies research abstracts at 72% with zero examples. Naive Bayes matches it with 490 labelled examples, then beats it while running ~200× faster on ~1/5,600th of the energy, and giving the same answer every time."
section: blog
draft: true
---

<!--
SCAFFOLD — notes in HTML comments are for drafting and won't render.

THESIS: LLMs are being used where deterministic tooling would do the job cheaper and
more accurately. Classification is a small, measurable example with small absolute power
numbers, but the ratio is what matters once you extrapolate to bigger problems.
An LLM is a fine stopgap for getting to market quickly; long-term, a deterministic model
wins on cost and (probably) on accuracy.

Three pillars: POWER, SPEED, ACCURACY (with consistency as part of accuracy).

Scope: results only. The full report lives at /blog/naive-bayes-vs-decider-report.
Content axes: AI Architecture (model selection, energy economics) and
AI Decision-Making (when the LLM is the wrong tool).
-->

<!--
HOOK (1–2 paragraphs)
- The pattern you keep seeing: an LLM call wherever a decision has to be made (route this
  ticket, tag this document, pick a category), because it's quick to wire up and it
  "just works".
- AWS's Strands Decider is a good test case: a 2B model built specifically for these
  decisions, so it's the LLM approach at its leanest, not a straw man.
- The question: how many labelled examples does a boring, tuned Naive Bayes need to catch
  up, and what does each cost to run?
- Punchline: 70 per class. After that, NB wins on all three counts.
-->

## What we tested

<!--
One short paragraph — just enough to read the results.
- Task: sort research abstracts into 7 fields (Web of Science WOS-46985).
- Chosen because it isn't in Decider's training data; overlapping items removed.
- Decider: zero-shot, only label names and descriptions.
- NB: scikit-learn Multinomial/Complement NB, tuned with cross-validation, trained on
  1 to 1,000 labelled examples per class.
- Same 9,996 test items for both, on one RTX 3090 + Ryzen 9 3900, energy from hardware counters.
-->

The methodology, contamination check and every table are in the [full report](/blog/naive-bayes-vs-decider-report).

## The results

| | Naive Bayes | Decider 2B |
| --- | --- | --- |
| Labelled examples needed to match | 70 per class (490 in total) | none (label wording only) |
| Accuracy at 100 per class | 0.748 | 0.721 (zero-shot) |
| Accuracy at 1,000 per class | 0.800 | 0.721 |
| Energy per 1,000 predictions | 1.47 mWh | 8.22 Wh (~5,600×) |
| Latency per item (p50) | 0.5 ms on one CPU thread | 96 ms on a GPU (~194×) |
| Whole test set (9,996 items) | 1.4 s | 17 min |
| Training cost | 86 mWh incl. full tuning ≈ 10 Decider predictions | sunk (AWS's) |
| Same input, same answer? | always, byte for byte | only if the batch and prompt are pinned |

<!--
Keep commentary here to a sentence or two; each pillar gets its own section below.
-->

## Accuracy: 490 labels is all it takes

<!--
- The learning curve: 20/class → 0.62, 50/class → 0.70, 70/class → tie, 1,000/class → 0.80.
- Decider is frozen at 0.72 on this task. The only lever is rewording the labels (the
  taxonomy-informed wording got 0.71 on dev; a blind first attempt got 0.66).
- NB keeps improving with every label you add. That's the long-term accuracy argument.
- Optional: where Decider struggles (Biochemistry vs Medical, Civil vs Mechanical), i.e.
  domain boundaries that labelled data teaches and a general model has to guess at.
- Fairness: Decider's confidence scores are better calibrated (ECE 0.04 vs 0.21).
-->

## Speed: milliseconds vs a GPU queue

<!--
- 0.5 ms on one CPU thread vs 96 ms on a dedicated GPU, about 194×.
- The whole test set: 1.4 s vs 17 minutes.
- Throughput ceiling: ~10 items/s on a 3090 means ~860k/day, and the GPU does nothing else.
  NB scales on any spare CPU core.
- The mechanics: NB is a sparse dot product and an argmax. Decider runs a 2B-parameter
  forward pass over the abstract plus a prompt containing all 7 options, for every item.
-->

## Power: small numbers, big ratio

<!--
- The honest framing first: 8.22 Wh per 1,000 predictions is ~8 kWh per million.
  For a categoriser, that's not going to break anyone's budget.
- The point is the ratio: ~30 J vs ~5 mJ per decision, about 5,600×. And Decider is a
  lean 2B model built for this; the general-purpose models people actually reach for
  are much bigger.
- Training doesn't close the gap: tuning + training NB costs less than 10 Decider calls.
  A refit costs less than one.
- EXTRAPOLATE: the same pattern in bigger problems.
  [TODO: Q1 — which 1–2 examples? e.g. extraction, validation, routing inside agent
  loops, log triage. Any numbers you can stand behind?]
- Tie to the SME lens: power is GPU hardware, cloud bills, and (for you) solar capacity.
-->

## Consistency: same question, different answer

<!--
- NB gave byte-identical output across every run and every retrain.
- Decider is repeatable only when everything is pinned. Change the batch size or which
  items share a batch and ~1 in 300 predictions flips. Change the order of the options
  and 1 in 6 flips (it prefers Medical Science when it's listed first).
- Why it matters in production: inference servers batch dynamically, and prompts get
  edited. So the same input can get a different answer next week, without anyone
  touching the model.
  [TODO: Q2 — see conflict note in chat]
- Debugging/audit angle: a deterministic model can explain a decision and reproduce it.
-->

## The LLM is the stopgap

<!--
The implications section — the reason the post exists.
1. Ship with the LLM if it gets you to market faster. Zero labels, decent accuracy, day one.
2. Use that time to collect labels: log the LLM's decisions, correct them, build the
   training set. 490 labels gets you parity here; that's days of work, not months.
   (At 72%, the LLM's own output isn't good enough as unreviewed training data.)
3. Then replace it with the deterministic model: cheaper, faster, repeatable, and it
   keeps improving as labels accumulate.
4. Budget for the swap from the start. The LLM call is a prototype, not the architecture.
5. Where the LLM still earns its place: open-ended inputs, no stable label set, too few
   examples, or a fallback for low-confidence cases.
-->

## Caveats

<!--
Short and honest.
- One dataset, one 7-class task, one GPU.
- Labelling cost isn't counted in the report (but see "The LLM is the stopgap").
- Decider's label wording was written from the dataset's taxonomy, which helps it.
- The base model's pre-training data is unknown; if WOS is in it, that favours Decider.
- The 70/class crossover is a statistical tie; 80+ is a clear NB win.
-->

## Wrapping up

<!--
- The decision rule in one sentence: if the decision has a fixed set of answers and you
  can collect a few hundred examples, an LLM is the stopgap, not the solution.
- Link to the full report.
- What's next: [TODO: Q3]
-->
