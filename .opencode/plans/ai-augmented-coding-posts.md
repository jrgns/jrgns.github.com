# AI-Augmented Coding Blog Series — Plan

Five-part series on AI-augmented development from a practitioner's lens. Each post is tracked and scaffolded independently.

---

## Post 1: Managing Agents vs Managing People

**Status:** Not started
**Source:** `input/ai_augmented_coding_productivity.md` (+ light reference to `token_budget_allocation.md`)
**Axes:** AI Management (primary), AI Architecture (secondary)
**Content type:** Thought piece, ~1500-2000 words

### Thesis
Managing AI coding agents is harder than managing developers, not because the AI is dumb, but because it remembers nothing. The shift from managing people to managing agents isn't about delegation — it's about context architecture.

### Core Material
- AI shifts coding management from people to agents — same concepts, different target
- Better planning = better code regardless, now magnified because it takes minutes instead of hours to plan
- Skilled humans still needed for prompting — a painter won't write a system just because you told them to
- Harness design matters: testing, linting, security — you need to *know* what context to include
- Higher quality output means expectations shift to parallel projects, not just faster single projects

### Gaps to Fill
- Concrete examples of harness design (what actually needs to be in the harness?)
- What "good planning" looks like with AI vs without

### Working Titles
- Direct: "Managing AI Agents Is Harder Than Managing Developers"
- Tension: "The Problem With AI Coding Isn't The AI"
- Question: "What Nobody Says About AI-Augmented Development"

---

## Post 2: The Context Tax of AI-Coding

**Status:** Not started
**Source:** `input/coding_context_aid_loss.md`
**Axes:** AI Architecture (primary), AI Management (secondary)
**Content type:** Observational analysis, ~1000-1500 words

### Thesis
The hidden cost of AI-augmented coding isn't the tokens — it's the context you stopped writing yourself. Each time you prompt instead of build, you pay a future debugging tax that exceeds the saved development time.

### Core Material
- Writing code yourself builds a sense of how the system works; skipping that erodes system understanding
- Debugging becomes harder without that knowledge — pointing an AI to the right area is more efficient than "fix this"
- Lost context means higher AI costs because agents start fresh each time without that internal map
- Same principle applies to new developers: context switching into a codebase takes hours even before hitting the bug

### Gaps to Fill
- Concrete scenario or story (e.g. a bug you diagnosed quickly thanks to having written the system)

### Working Titles
- Direct: "The Hidden Cost of AI-Augmented Coding"
- Contrarian: "Prompting Instead of Building Is Making Your Project More Expensive"
- Tension: "What AI Coding Costs That Nobody Talks About"

---

## Post 3: Token Budgets as Management

**Status:** Not started
**Source:** `input/token_budget_allocation.md` (+ reference to `general_vs_specialized_ai_models.md`)
**Axes:** AI Management (primary), AI Decision-Making (secondary)
**Content type:** Practical guide, ~800-1200 words

### Thesis
Budgeting for token spend is a planning and management problem, not a technical one. You can't model it — you can only observe it. Start small, bucket by use case, scale based on what you see.

### Core Material
- How do you allocate budget when you have no baseline? Small buckets, observe, then adjust
- Token allocation as a management problem, not a technical one
- Running costs differ between operational categories: Run vs Build vs Transform
- SME lens: small businesses don't need enterprise-grade token models, they need small starting buckets with room to grow
- Milestone-based token expansion (from the consultant note)

### Gaps to Fill
- What do "Run vs Build vs Transform" budgets look like in practice for an SME?
- Concrete token cost ranges (low, medium) for each category

### Working Titles
- Direct: "How To Budget For AI Spend"
- Contrarian: "You Can't Model AI Token Costs — You Shouldn't Try"
- Question: "How Do You Budget For Something You've Never Used Before?"

---

## Post 4: Token Budgets as a Business Practice

**Status:** Not started
**Source:** `input/token_budget_allocation.md` (+ possibly other notes)
**Axes:** AI Decision-Making (primary), AI Management (secondary)
**Content type:** Analytical, ~1200-1800 words

### Thesis
Token budgets aren't a dev ops problem — they're a business management problem. The same frameworks that govern project spend, consulting milestones, and operational vs strategic budgets apply to AI token budgets. The difference is scale and velocity.

### Core Material
- Token budgets as an extension of project management and resource allocation
- Milestone-based token expansion
- The consultant approach: set targets, give teams room to grow
- Connection to broader AI governance for SMEs

### Gaps to Fill
- This note is thin on source material. May need additional voice notes or the author's input on real-world experience with token budgeting at scale
- How different business functions (sales ops, support, dev) map to token categories

### Working Titles
- Direct: "Token Budgets Are Business Problem, Not Technical Ones"
- Contrarian: "Stop Treating AI Tokens Like Infrastructure Costs"
- Question: "Can Project Management Frameworks Work For AI?"

---

## Post 5: General vs Specialized Models

**Status:** Not started
**Sources:** `input/general_vs_specialized_ai_models.md` + `input/llm_vs_finetune_experiment.md`
**Axes:** AI Architecture (primary), AI Decision-Making (secondary)
**Content type:** Technical comparison + SME lens, ~1500-2500 words

### Thesis
General frontier models are getting good enough to challenge specialized models for many tasks — but the economics flip at a certain scale. For most SMEs, higher operating cost makes sense. For enterprises, the specialization ROI is real. The real question isn't which is better, it's where the inflection point is.

### Core Material
- The meeting challenge: LLM accuracy vs specialized ML models for classification tasks (e.g. photo classification)
- Efficiency trade-offs: growing prompt size vs targeted feedback loops for general models
- Token cost per image with LLM grows as prompt/context grows; specialized model has fixed capex + lower opex
- SME lens: do they pay higher daily operating cost or spend capex on building a specialized system?
- Proposed experiment: LLM classification with thumbs feedback vs image model with thumbs feedback — track accuracy and cost curves

### Gaps to Fill
- Real examples beyond photo classification (what else? document classification, error categorization?)
- The actual accuracy gap — is it narrow or wide for common tasks?
- Capex vs opex comparison numbers, even rough estimates

### Working Titles
- Direct: "When Specialized Models Beat General AI"
- Contrarian: "Your SME Doesn't Need A Fine-Tuned Model"
- Question: "Is A General AI Model Good Enough?"

---

## Ordering Rationale

1. **Post 1** (Agents vs People) — Establishes the author's authority on AI management; the strongest source material
2. **Post 2** (Context Tax) — Technical depth, builds on the same themes but from a new angle
3. **Post 3** (Token Budgets as Management) — Practical, lighter read; transitions to business topic
4. **Post 4** (Token Budgets as Business Practice) — Connects tech costs to business practices; SME strategic thinking
5. **Post 5** (General vs Specialized) — Architecture-focused, closes the series with a broader technical question

Posts 1-2 are tightly connected. Posts 3-4 are thematically linked but each can stand alone. Post 5 operates independently.

---

## Process

Each post is scaffolded independently using the `blog-from-voice` skill:
1. Run `/blog-from-voice input/<source-filename>` for the primary source
2. For short notes (Post 3 source is ~1 minute), probe for additional depth
3. Fill gaps from the author's experience before writing
4. Save scaffold to `src/content/blog/<slug>.md` as draft
