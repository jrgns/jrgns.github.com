# jrgns.net

The personal blog and portfolio of **Jurgens du Toit** — a systems developer
from South Africa writing about Elasticsearch, the ELK stack, and the messy,
fascinating ways software fits together.

Live at **[jrgns.net](https://jrgns.net)**.

## Tech stack

- **[Astro](https://astro.build) 4** — static site generator
- **Tailwind CSS 3** — styling, with a custom "Engineer's Notebook" design system
- **Markdown content collections** — blog posts in `src/content/blog/`
- **Shiki** — syntax highlighting
- Deployed as static files to **GitHub Pages**

## Getting started

Requires Node.js ≥ 18.

```bash
npm install      # install dependencies
npm run dev      # start the dev server at http://localhost:4321
npm run build    # build the static site into dist/
npm run preview  # preview the production build locally
```

> **Heads up:** `npm run build` renders every page correctly but currently exits
> with a non-zero code due to a known upstream crash in `@astrojs/sitemap`. The
> generated `dist/` is complete and usable regardless.

## Project layout

| Path | What's there |
| --- | --- |
| `src/pages/` | Routes: home, `writing/`, `archive/`, `talks/` |
| `src/content/blog/` | Blog posts (Markdown + frontmatter) |
| `src/layouts/Base.astro` | Shared page shell (head, header, footer, sidebar) |
| `src/components/` | `Header`, `Footer`, `ProfileCard`, `PostCard`, `TalkCard` |
| `src/assets/css/theme.css` | Design system: colour tokens, fonts, prose, effects |
| `tailwind.config.mjs` | Tailwind theme wired to the CSS-variable colour tokens |
| `astro.config.mjs` | Site config, integrations, and legacy-URL redirects |

## Writing a post

Add a Markdown file under `src/content/blog/` with frontmatter:

```markdown
---
title: My new post
date: 2026-05-31
description: A one-line summary used in listings and meta tags.
---

Your content here…
```

It will be published at `/archive/<filename>`.

## Design

The site uses a warm "Engineer's Notebook" theme — graph-paper cream, ink text,
and a single vermilion accent, with Fraunces / Hanken Grotesk / JetBrains Mono.
Light and dark modes are handled by flipping CSS variables in
`src/assets/css/theme.css` (no `dark:` utility classes), so component markup
stays clean. See `AGENTS.md` for the full design-system notes.

## Licence

See [LICENSE.txt](LICENSE.txt).
