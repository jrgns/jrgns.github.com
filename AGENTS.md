# jrgns.net

Personal blog and portfolio site for Jurgens du Toit, hosted on GitHub Pages.

## Tech Stack
- **Framework**: [Astro](https://astro.build) 4 (static output)
- **Styling**: Tailwind CSS 3 via `@astrojs/tailwind`
- **Content**: Astro content collections — plain Markdown in `src/content/`
- **Syntax Highlighting**: Shiki (`github-dark` theme), configured in `astro.config.mjs`
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
src/
  layouts/Base.astro   # HTML shell: <head>, fonts, header/footer, optional profile sidebar
  components/          # Header, Footer, ProfileCard, PostCard, TalkCard
  pages/              # index, writing/, archive/ (+ [...slug]), talks/
  content/blog/       # Blog posts (Markdown, frontmatter: title, date, description)
  content/config.ts   # Content collection schemas (blog, writing)
  assets/css/         # theme.css (design system) + pygments.css
  assets/img/         # Post images
  assets/talks/       # Talk decks (PDFs + Reveal.js HTML)
  lib/site.ts         # Site-wide constants (title, social links)
```

## Design System ("Engineer's Notebook")
- Warm graph-paper cream + ink text + a single vermilion accent; faint grid and paper grain.
- **Semantic colour tokens** (`paper`, `paper-2`, `ink`, `ink-soft`, `ink-faint`, `line`, `accent`, `highlight`) are defined as CSS variables in `src/assets/css/theme.css` and exposed to Tailwind in `tailwind.config.mjs`.
- **Dark mode flips the CSS variables** via `@media (prefers-color-scheme: dark)`. Components therefore use plain `bg-paper`/`text-ink` with **no `dark:` variants** — never reintroduce `dark:` classes; adjust the variables instead.
- Reusable primitives live in `theme.css`: `.label`, `.cursor`, `.link-marker`, `.link-grow`, `.note-card`, `.perforate`, and hand-rolled `.prose` styling (no typography plugin is installed).

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

## Content Conventions
- Blog posts: Markdown in `src/content/blog/` with frontmatter `title`, `date`, optional `description`/`image`/`draft`. They render at `/archive/<slug>`.
- Old `/content/*.html` URLs are 301-redirected to `/archive/*` via `astro.config.mjs`.
- Talk decks (PDF or Reveal.js) live in `src/assets/talks/` and are listed in `src/pages/talks/index.astro` and the homepage.
