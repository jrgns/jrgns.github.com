# Astro Migration Plan — jrgns.net

## Goals
1. Migrate from Jekyll/Bootstrap 2.x to Astro + Tailwind CSS
2. Create new `/writing/` section for AI-writing content (tutorials, case studies, opinion pieces)
3. Move 40 existing blog posts to `/archive/` section with preserved URLs
4. Modern, responsive design with dark mode support
5. Keep Atom + RSS feeds

## Tech Stack
- Astro + Tailwind CSS + `@astrojs/content` + `@astrojs/rss`
- Shiki for syntax highlighting
- System font stack + monospace for code
- Dark mode (system preference)
- GA4 analytics (placeholder ID)

## URL Mapping
- Old posts: `/blog/{slug}` → `/archive/{slug}`
- Custom permalinks: 8 rewritten to `/archive/{slug}/`
- `content/` HTML redirects: 31 301 rewrites
- Static pages: `.html` extension removed
- Feeds: keep `/atom.xml`, add `/feed.xml`

## Implementation Steps
1. Scaffold Astro project with Tailwind
2. Configure content collections (`blog` + `writing`)
3. Build layout shell (Base.astro) with dark mode, GA4, system fonts
4. Build components (Header, Footer, PostCard, TalkCard, CodeBlock)
5. Migrate 40 posts from Jekyll MD to Astro MDX
6. Create pages (index, writing/index, writing/slug, archive/index, archive/slug, talks, hire-me, resources)
7. Set up Atom + RSS feeds
8. Configure redirects for old permalinks
9. Copy assets (talks PDFs, images)
10. Design polish (responsive, dark mode)
11. Configure GitHub Pages deployment
12. Test locally, deploy

## Open Items (Resolved)
- GA4: placeholder ID to be replaced later
- Dark mode: enabled (system preference)
