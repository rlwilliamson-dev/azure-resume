/**
 * Tags a topic's comparison table so it can be styled like a comparison rather
 * than like a list.
 *
 * Those tables all answer the same question for a given track, RHEL against
 * Debian or Linux against Windows against macOS, and a reader moving between
 * topics reads them as a set. Left to auto layout they size
 * themselves to whatever text happens to be in them, so the same three columns
 * land in a different place in every lesson and the eye has to re-find them each
 * time. One class lets CSS give them a shared geometry.
 *
 * Deliberately narrow. Every other table in the track keeps auto layout, because
 * a table whose first column holds a number ("4") should not be handed thirty
 * percent of the width, and several of them are exactly that shape.
 *
 * Runs after the build, for the same reason as terminal-lines: this Astro
 * version does not use the unified Markdown processor, and swapping it out to
 * add one attribute would quietly change how the topics' raw-HTML blocks parse.
 */
import { readFile, writeFile, readdir } from 'node:fs/promises';
import path from 'node:path';

/**
 * The heading the comparison table sits under, as rendered.
 *
 * Matched on the word "Across" rather than on a specific heading, because each
 * track names its own: Linux+ compares distributions, Network+ compares
 * platforms. The exact heading per track lives in config/tracks.ts, which this
 * cannot import, since a build integration runs as plain JavaScript in Node
 * while that file is TypeScript compiled for the site. So the convention carries
 * it: a comparison section heading begins with "Across", and COMPARE_META says
 * so in its own comment.
 */
const HEADING = /<h2[^>]*>\s*(?:<a[^>]*>)?\s*Across\s/i;

async function walk(dir) {
  const out = [];
  let entries;
  try {
    entries = await readdir(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...(await walk(full)));
    else if (entry.name.endsWith('.html')) out.push(full);
  }
  return out;
}

export default function compareTables() {
  return {
    name: 'compare-tables',
    hooks: {
      'astro:build:done': async ({ dir, logger }) => {
        const files = await walk(path.join(dir.pathname, 'learn'));
        let tagged = 0;
        let pages = 0;

        for (const file of files) {
          const html = await readFile(file, 'utf8');
          const heading = HEADING.exec(html);
          if (!heading) continue;

          // The first table after the heading is the comparison.
          const after = html.slice(heading.index);
          const open = after.indexOf('<table');
          if (open === -1) continue;

          // Unless another h2 comes first: a topic whose section is prose must
          // not claim the table belonging to the section below it.
          const between = after.slice(heading[0].length, open);
          if (/<h2[\s>]/i.test(between)) continue;

          const abs = heading.index + open;
          const next =
            html.slice(0, abs) +
            html.slice(abs).replace('<table', '<table class="compare"', 1);

          if (next !== html) {
            await writeFile(file, next);
            tagged += 1;
          }
          pages += 1;
        }

        logger.info(`tagged ${tagged} comparison table(s) across ${pages} page(s)`);
      },
    },
  };
}
