import type { Config } from "tailwindcss";
import plugin from "tailwindcss/plugin";

export default {
  content: {
    relative: true,
    files: [
      "./src/layouts/**/*.astro",
      "./src/components/**/*.astro",
      "./src/pages/**/*.astro",
      "./src/pages/**/*.mdx",
    ],
  },
  darkMode: "media",
  theme: {
    extend: {
      fontFamily: {
        sans: [
          "system-ui",
          "-apple-system",
          "Segoe UI",
          "Roboto",
          "Helvetica",
          "Arial",
          "sans-serif",
        ],
        mono: [
          "'JetBrains Mono'",
          "'Fira Code'",
          "'Lucida Console'",
          "'Andale Mono'",
          "monospace",
        ],
      },
      colors: {
        primary: {
          50: "#f0f9ff",
          100: "#e0f2fe",
          200: "#bae6fd",
          300: "#7dd3fc",
          400: "#38bdf8",
          500: "#0ea5e9",
          600: "#0284c7",
          700: "#0369a1",
          800: "#075985",
          900: "#0c4a6e",
        },
      },
    },
  },
} satisfies Config;
