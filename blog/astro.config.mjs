// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://rlwilliamson.dev',
  base: '/blog',
  trailingSlash: 'ignore',
  integrations: [sitemap()],
  markdown: {
    shikiConfig: {
      // Code block theme tuned to match the dark terminal aesthetic
      theme: 'tokyo-night',
      wrap: true,
    },
  },
  build: {
    format: 'directory',
  },
});
