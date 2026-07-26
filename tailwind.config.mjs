import type { Config } from "tailwindcss";

export default {
  content: {
    relative: true,
    files: [
      "./src/layouts/**/*.astro",
      "./src/components/**/*.astro",
      "./src/pages/**/*.astro",
      "./src/pages/**/*.mdx",
      "./src/pages/**/*.md",
    ],
  },
  darkMode: "media",
  theme: {
    extend: {
      fontFamily: {
        // Characterful high-contrast display serif for headings.
        display: ["Fraunces", "Georgia", "serif"],
        // Warm, friendly grotesque for body copy.
        sans: ["'Hanken Grotesk'", "system-ui", "-apple-system", "sans-serif"],
        // Engineering labels, metadata, code.
        mono: ["'JetBrains Mono'", "'SFMono-Regular'", "Consolas", "monospace"],
      },
      // Semantic tokens are driven by CSS variables (see theme.css) so that
      // light/dark are handled in one place and components stay clean.
      colors: {
        paper: "var(--paper)",
        surface: "var(--surface)",
        "paper-2": "var(--paper-2)",
        ink: "var(--ink)",
        "ink-soft": "var(--ink-soft)",
        "ink-faint": "var(--ink-faint)",
        line: "var(--line)",
        accent: "var(--accent)",
        "accent-soft": "var(--accent-soft)",
        highlight: "var(--highlight)",
      },
      keyframes: {
        blink: {
          "0%, 49%": { opacity: "1" },
          "50%, 100%": { opacity: "0" },
        },
        "rise-in": {
          "0%": { opacity: "0", transform: "translateY(12px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
      },
      animation: {
        blink: "blink 1.1s steps(1) infinite",
        "rise-in": "rise-in 0.6s cubic-bezier(0.22, 1, 0.36, 1) both",
      },
    },
  },
} satisfies Config;
