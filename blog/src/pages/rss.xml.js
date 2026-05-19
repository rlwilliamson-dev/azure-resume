import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';

export async function GET(context) {
  const posts = await getCollection('posts', ({ data }) => !data.draft);
  const sorted = posts.sort(
    (a, b) => b.data.publishDate.valueOf() - a.data.publishDate.valueOf()
  );
  const base = (import.meta.env.BASE_URL || '/').replace(/\/$/, '');

  return rss({
    title: 'Ryan Williamson — Blog',
    description:
      'Writing about Azure, DevOps, infrastructure as code, cybersecurity, and home-lab tinkering.',
    site: context.site ?? 'https://rlwilliamson.dev',
    items: sorted.map((post) => ({
      title: post.data.title,
      description: post.data.description,
      pubDate: post.data.publishDate,
      link: `${base}/${post.id}`,
      categories: post.data.tags,
    })),
    customData: `<language>en-us</language>`,
  });
}
