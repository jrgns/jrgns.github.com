# jrgns.net

Personal blog and portfolio site for Jurgens du Toit, hosted on GitHub Pages.

## Tech Stack
- **Framework**: [Astro](https://astro.build) 4 (static output)
- **Styling**: Tailwind CSS 3 via `@astrojs/tailwind`
- **Content**: Astro content collections — plain Markdown in `src/content/`
- **Syntax Highlighting**: Shiki (`github-dark-dimmed` theme), configured in `astro.config.mjs`. Posts are plain Markdown, so the setting that matters is top-level `markdown.shikiConfig` — the copy inside `mdx()` only applies to `.mdx` files.
- **Fonts**: Fraunces (display), Hanken Grotesk (body), JetBrains Mono (labels/code) — loaded from Google Fonts in `Base.astro`
- **Feeds & SEO**: `@astrojs/rss` (`/atom.xml`) and `@astrojs/sitemap`
- **Hosting**: GitHub Pages
- **Custom Domain**: `jrgns.net` (configured via `CNAME`)

> Note: the repo still contains legacy Jekyll files (`_config.yml`, `_layouts/`, `_posts/`, root `*.html`) from the previous incarnation. They are **not** used by the build — Astro is the source of truth.

## Repository
- **Remote**: `https://github.com/jrgns/jrgns.github.com`
- **Branch**: `master` (GitHub Pages default branch)

## Project Structure
```
astro.config.mjs       # Astro config: site URL, integrations, redirects (old URLs -> /archive/*)
tailwind.config.mjs    # Design tokens: fonts, semantic colours (paper/ink/accent...), animations
CNAME                  # Custom domain: jrgns.net
public/                # Served verbatim at the site root (favicon, robots, CV PDFs, talks/)
  talks/              # Talk decks: PDFs + Reveal.js HTML, reached at /talks/*
src/
  layouts/Base.astro   # HTML shell: <head>, fonts, header/footer, optional profile sidebar
  components/          # Header, Footer, ProfileCard, PostCard, TalkCard
  pages/              # index, writing/, archive/ (+ [...slug]), talks/
  content/blog/       # Blog posts (Markdown, frontmatter: title, date, description)
  content/config.ts   # Content collection schemas (blog, writing)
  assets/css/         # theme.css (design system)
  assets/img/         # Post images
  lib/site.ts         # Site-wide constants (title, social links)
```

## Design System ("Engineer's Notebook")
- Cool graph-paper blue + navy ink + a single azure accent; faint grid and paper grain. Dark mode is the muted **"Dusk Slate"** palette — a desaturated navy-slate deliberately kept near 9:1 rather than the near-black/near-white glare it replaced.
- **Semantic colour tokens** (`paper`, `surface`, `paper-2`, `ink`, `ink-soft`, `ink-faint`, `line`, `accent`, `accent-soft`, `highlight`) are defined as CSS variables in `src/assets/css/theme.css` and exposed to Tailwind in `tailwind.config.mjs`. Supporting tokens that no component reads directly: `--selection-ink`, `--code-bg`, `--code-ink`, `--canvas-glow`, `--grain-opacity`.
- **Three elevations**, and they must stay in this order: `paper` (page canvas, carries the grid) → `surface` (the `.panel` behind the main content column) → `paper-2` (cards sitting on the panel).
- **Dark mode flips the CSS variables** via `@media (prefers-color-scheme: dark)` *and* a matching `:root[data-theme="dark"]` block for the header toggle — **keep the two in sync**. Components therefore use plain `bg-paper`/`text-ink` with **no `dark:` variants** — never reintroduce `dark:` classes; adjust the variables instead.
- **Keep noise out from under the text.** Body copy sits on `.panel`, never directly on the canvas. In dark, `--canvas-glow` is `transparent` and `--grain-opacity` drops to `0.3`, so the texture lives in the margins. Don't undo this by putting content back on the raw canvas.
- Reusable primitives live in `theme.css`: `.panel`, `.label`, `.cursor`, `.link-marker`, `.link-grow`, `.note-card`, `.perforate`, and hand-rolled `.prose` styling (no typography plugin is installed).
- Shiki writes its own `background-color` **inline** on highlighted `<pre>`, which beats `.prose pre`. `--code-bg`/`--code-ink` therefore only cover plain `<pre>`; they're pinned to `github-dark-dimmed`'s values so both look identical. Change them together with the Shiki theme.

## Global Configuration
This project follows the global AGENTS.md for SDLC and general conventions.

## Key Constraints
- **Static only**: no server runtime; everything is prerendered by `astro build` into `dist/`.
- **Known build wart**: `astro build` generates every page but currently **exits code 1** on a pre-existing crash in `@astrojs/sitemap`'s `build:done` hook. Treat a successful page emit (not the exit code) as the signal that the build worked.
- **Legacy files**: don't edit the root Jekyll `*.html`/`_layouts`/`_posts` — they're dead weight pending cleanup.

## Local Development
```bash
npm install
npm run dev      # dev server at http://localhost:4321
npm run build    # static build into dist/ (see "Known build wart" above)
npm run preview  # serve the production build locally
```

## Future Considerations

- **Search (Algolia)**: The site has no search yet. Recommended approach when ready: use a free Algolia account with a build-time Node indexer that pushes `src/content/blog/` entries to Algolia, plus an `@algolia/autocomplete-js` search component in the header. Free tier covers 10k records and 10k searches/month — ample for a personal blog.

## Audience
- **Primary**: technical leaders and engineering managers at SMEs who need to adopt AI.
- **Secondary**: larger-corporate readers — the author's corporate experience naturally appeals to them.

## Editorial Direction
The blog serves a deliberate positioning goal: to establish the author as a recognised authority in **AI architecture and the management of AI systems** (both technical and human). Every piece should, as naturally as possible, reinforce this.

### Voice and Tone
- **Hands-on practitioner**, not an academic or a hype-maker. Grounded in real decisions, real trade-offs, and real costs.
- **Pragmatic and technically rigorous** — LLMs are the wrong tool more often than the industry admits. Show where simpler methods (Bayesian filters, small models, static tooling) win on cost, latency, or accuracy.
- Write from the seat of experience. The reader should feel that the author has **built, broken, and rebuilt** systems they're talking about.

### Content Axes (every post should lean into at least one)
Each blog post should advance the author's credibility along one or more of these dimensions:

1. **AI Architecture** — System design choices, model selection, token economics, tooling over agent-dependency, build-vs-buy, general-vs-specialized trade-offs. Concrete diagrams, code snippets, or benchmark-style comparisons are welcome.
2. **AI Management** — How teams and orgs actually work *with* AI. Prompting as a skill, AI champions, agent harness design, testing, linting, security. Managing cost and budget. The shift from managing people to managing agents.
3. **AI Decision-Making** — Strategic thinking around AI adoption: risk, procurement, vendor evaluation, "AI washing", building defenses against hype.

### Content Guidelines
- **Pragmatism over hype.** Question popular assumptions. If an LLM is the simplest path, say so and show the cost. If a naive Bayes filter or a fine-tuned classifier does the job, make the case.
- **SME lens.** Most readers run or advise small-to-medium businesses. Ground decisions in resource constraints — money, time, skills. Enterprise-scale solutions are only relevant when they illuminate something an SME can apply differently.
- **Depth over frequency.** 1-3 posts per month is the target. Quality matters more than cadence. One well-reasoned, hands-on post beats three shallow takeaways.
- **Light domain cross-pollination is fine.** If an insight about AI management naturally ties to architecture decisions, make the link. Don't force it.
- **Show the mechanics.** Don't just say "testing matters." Show *what* gets tested, *why*, and the cost of skipping it. Concrete details build authority.

## Content Conventions
- Blog posts: Markdown in `src/content/blog/` with frontmatter `title`, `date`, optional `description`/`image`/`draft`. They render at `/archive/<slug>`.
- Old `/content/*.html` URLs are 301-redirected to `/archive/*` via `astro.config.mjs`.
- Talk decks (PDF or Reveal.js) live in `public/talks/` so they're served verbatim at `/talks/*`, and are listed in `src/pages/talks/index.astro` and the homepage. (They must be in `public/`, not `src/assets/` — only `public/` is copied to the build root.)
