# jrgns.net

Personal blog and portfolio site for Jurgens du Toit, hosted on GitHub Pages.

## Tech Stack
- **Static Site Generator**: Jekyll (GitHub Pages default)
- **Markdown Processor**: kramdown
- **Syntax Highlighting**: pygments
- **CSS Framework**: Bootstrap 2.x (Spacelab theme)
- **Hosting**: GitHub Pages via `jrgns.github.com` repository
- **Custom Domain**: `jrgns.net` (configured via `CNAME`)

## Repository
- **Remote**: `https://github.com/jrgns/jrgns.github.com`
- **Branch**: `master` (GitHub Pages default branch)

## Project Structure
```
_config.yml          # Minimal Jekyll config (kramdown, pygments)
CNAME               # Custom domain: jrgns.net
index.html          # Landing page with talks list and recent blog posts
blog-index.html     # Blog archive page
_layouts/           # Jekyll layouts (default.html, post.html, writeup.html)
_posts/             # Blog post markdown files
talks/              # Talk slides (PDFs)
css/                # Bootstrap, Spacelab theme, custom site.css, pygments.css
js/                 # Custom JavaScript
img/                # Images
fonts/              # Font files
content/            # Additional content pages
resources.html      # Resources page
hire-me.html        # Hiring/consulting page
```

## Global Configuration
This project follows the global AGENTS.md at `~/.config/opencode/AGENTS.md` for SDLC, Docker, and general conventions.

## Key Constraints
- **No Gemfile**: The site uses GitHub Pages' built-in Jekyll; no custom plugins or gems.
- **No Docker Compose Required**: This is a static site served directly by GitHub Pages. Local development can use `jekyll serve` or Docker's `jekyll/jekyll` image if needed.
- **Bootstrap 2.x**: The site uses legacy Bootstrap classes (`row-fluid`, `span11`, `icon-*`). Any UI changes should maintain this version unless a migration is explicitly planned.

## Local Development
```bash
docker run --rm -it -v "$(pwd)":/srv/jekyll -p 4000:4000 jekyll/jekyll jekyll serve
```

## Content Conventions
- Blog posts live in `_posts/` with Jekyll front matter, categorized under `blog`.
- Talk slides are PDFs in `talks/`.
- Posts use the `post.html` layout; writeups use `writeup.html`.
