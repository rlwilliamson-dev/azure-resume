// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import learnImages from './integrations/learn-images.mjs';
import terminalLines from './integrations/terminal-lines.mjs';
import compareTables from './integrations/compare-tables.mjs';
import tableScroll from './integrations/table-scroll.mjs';
import { hiddenTrackSlugs } from './src/config/tracks.ts';

// A track being written is not a track to submit for indexing. The slugs come
// from src/config/tracks.ts so there is one place to change, rather than a list
// here that drifts from the one the site renders.
const hidden = hiddenTrackSlugs().map((slug) => `/learn/${slug}`);
const isHidden = (url) =>
  hidden.some((prefix) => {
    const path = new URL(url).pathname.replace(/\/$/, '');
    return path === prefix || path.startsWith(`${prefix}/`);
  });

export default defineConfig({
  site: 'https://rlwilliamson.dev',
  // This project serves more than one section (/blog and /learn), so the base
  // is the site root and each section lives in its own src/pages subdirectory.
  // Section prefixes are constants in src/config/site.ts.
  base: '/',
  trailingSlash: 'ignore',
  integrations: [sitemap({ filter: (url) => !isHidden(url) }), learnImages(), terminalLines(), compareTables(), tableScroll()],
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
