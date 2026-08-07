// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import learnImages from './integrations/learn-images.mjs';

export default defineConfig({
  site: 'https://rlwilliamson.dev',
  // This project serves more than one section (/blog and /learn), so the base
  // is the site root and each section lives in its own src/pages subdirectory.
  // Section prefixes are constants in src/config/site.ts.
  base: '/',
  trailingSlash: 'ignore',
  integrations: [sitemap(), learnImages()],
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
