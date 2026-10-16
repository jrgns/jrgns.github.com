import { getCollection } from "astro:content";

/** Where a blog post lives: /blog/ for `section: blog` posts, /archive/ otherwise. */
export function postHref(
  section: "blog" | "archive" | undefined,
  slug: string
): string {
  return section === "blog" ? `/blog/${slug}` : `/archive/${slug}`;
}

/**
 * Every blog post that should be built. `draft: true` posts are left out of
 * production builds, but still show under `npm run dev` so they can be previewed.
 */
export async function getPosts() {
  return getCollection("blog", ({ data }) => !(import.meta.env.PROD && data.draft));
}
