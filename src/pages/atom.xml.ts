import rss from "@astrojs/rss";
import { getCollection } from "astro:content";

export async function GET(context: import("astro").Context) {
  const posts = await getCollection("blog");
  posts.sort((a, b) => b.data.date.getTime() - a.data.date.getTime());

  return rss({
    title: "Jurgens du Toit",
    description: "A blog about systems and the interwebs",
    site: context.site || "https://jrgns.net",
    items: posts.map((post) => ({
      title: post.data.title,
      link: `/archive/${post.slug}`,
      pubDate: post.data.date,
      description: post.data.description || "",
      content: post.body,
    })),
  });
}
