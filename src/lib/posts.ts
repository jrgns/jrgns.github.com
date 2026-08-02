/** Where a blog post lives: /blog/ for `section: blog` posts, /archive/ otherwise. */
export function postHref(
  section: "blog" | "archive" | undefined,
  slug: string
): string {
  return section === "blog" ? `/blog/${slug}` : `/archive/${slug}`;
}
