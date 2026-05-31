import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync } from "fs";
import { join, dirname, basename } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const postsDir = join(__dirname, "..", "_posts");
const outputDir = join(__dirname, "..", "src", "content", "blog");

if (!existsSync(outputDir)) {
  mkdirSync(outputDir, { recursive: true });
}

function slugify(str) {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function getPostInfo(filename) {
  const base = basename(filename, ".md");
  const parts = base.split("-");
  const dateStr = parts.slice(0, 3).join("-");
  const slug = slugify(parts.slice(3).join("-"));
  return { dateStr, slug, base };
}

function cleanTitle(raw) {
  return raw
    .replace(/\\:/g, ":")
    .replace(/\\"/g, '"')
    .trim();
}

function convertMarkdownToMdx(content) {
  // Extract title from front matter
  const titleMatch = content.match(/^\s*title:\s*["']?(.*?)["']?\s*$/m);
  const rawTitle = titleMatch ? titleMatch[1] : "";
  const title = cleanTitle(rawTitle);

  // Strip Windows line endings first
  content = content.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  // Remove Jekyll front matter
  content = content.replace(/^---\n([\s\S]*?)---\n?/, "");

  // Decode common HTML entities
  content = content
    .replace(/&amp;/g, "&")
    .replace(/&#(\d+);/g, (_, dec) => String.fromCharCode(dec));

  // Remove <!--break--> (Jekyll more separator) before any other < > processing
  content = content.replace(/<!--break-->/g, "");

  // Remove stray < at end of lines that's not part of an HTML tag
  // (e.g., "5. Intuitive and function DB Objects<" -> "5. Intuitive and function DB Objects")
  content = content.replace(/([a-zA-Z0-9])<\s*$/gm, "$1");

  // Escape < not followed by valid HTML start (/, !, ?, letter)
  content = content.replace(/<(?!\/?[a-zA-Z!?])/g, "&lt;");

  // Replace Jekyll highlight blocks with MDX-compatible code blocks
  content = content.replace(
    /{% highlight (\w+)(\s+linenos)?(\s+inline)? %\}\n([\s\S]*?){% endhighlight %}/g,
    (match, lang, linenos, inline, code) => {
      const indentedCode = code
        .split("\n")
        .map((line) => "  " + line)
        .join("\n");
      return "```" + lang + "\n" + indentedCode + "\n```\n";
    }
  );

  // Replace Jekyll links [text][number] with MDX format
  content = content.replace(
    /\[([^\]]+)\]\[(\d+)\]/g,
    (match, text, number) => {
      const linkMatch = content.match(
        new RegExp(`\\n\\[${number}\\]:\\s*(.+?)\\s*$`, "m")
      );
      if (linkMatch) {
        const url = linkMatch[1].replace(/^http:\/\//, "https://");
        return `[${text}](${url})`;
      }
      return text;
    }
  );

  // Convert remaining [text](url) http links to https
  content = content.replace(
    /\[([^\]]+)\]\((http[^)]+)\)/g,
    (match, text, url) => {
      return `[${text}](${url.replace(/^http:\/\//, "https://")})`;
    }
  );



  // Convert Jekyll headings with no space after # (e.g., "##Title" -> "## Title")
  content = content.replace(/^(\#{1,6})\S/gm, (match, hashes) => `${hashes} ${match[hashes.length]}`);

  // Clean up extra blank lines
  content = content.replace(/\n{3,}/g, "\n\n");
  content = content.trim();

  // Create a simple description from the first paragraph
  const firstParagraph = content.match(/^([^\n]*?[.!?])/);
  const description = firstParagraph ? firstParagraph[1] : "";

  return { title, content, description };
}

const allFiles = readdirSync(postsDir);
const files = allFiles.filter((f) => f.trim().endsWith(".md"));

console.log(`Found ${files.length} posts to convert`);

files.forEach((file) => {
  const fullPath = join(postsDir, file);
  const { dateStr, slug } = getPostInfo(file);
  let content = readFileSync(fullPath, "utf-8");

  const { title, content: mdxContent, description } = convertMarkdownToMdx(content);

  const descField = description
    ? `description: "${description.replace(/"/g, '\\"')}"`
    : "";

  const mdxFile = `---
title: "${title.replace(/"/g, '\\"')}"
date: ${dateStr}
${descField}
---

${mdxContent}
`;

  const outputPath = join(outputDir, `${slug}.md`);
  writeFileSync(outputPath, mdxFile, "utf-8");
  console.log(`  Created: ${basename(outputPath)}`);
});

console.log("Done!");
