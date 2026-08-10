/**
 * Wraps every table on a learn page in a horizontally scrollable container.
 *
 * Markdown tables have no wrapper of their own and no width constraint, so a
 * table wider than the column pushes the whole page sideways. Measured on a
 * 375px viewport, two ordinary tables in one Network+ topic came out at 419px
 * and 380px against 321px of available width, and the document scrolled
 * horizontally as a result. Every page on the site scrolls, not just the part
 * with the table on it, which is the worst version of the problem.
 *
 * The comparison tables do not have this fault, because `table.compare` is
 * fixed-layout at 100 percent width. Everything else is auto layout and sizes
 * itself to its content, which is correct on a desktop and unusable on a phone.
 *
 * This track is table-dense by nature: the ports table, cable categories,
 * connector types, DNS record types, error counters. So the fix belongs in one
 * place rather than in a per-topic habit of remembering to write narrow tables.
 *
 * Runs after the build, for the same reason as terminal-lines and
 * compare-tables: this Astro version does not use the unified Markdown
 * processor, and swapping it out to add one wrapper element would quietly change
 * how the raw HTML blocks in topics parse.
 */
import { readFile, writeFile, readdir } from 'node:fs/promises';
import path from 'node:path';

/** Wrappers that already provide the scroll, so a table inside one is left alone. */
const ALREADY_WRAPPED = /<div class="(?:distro-scroll|table-scroll)"[^>]*>\s*$/;

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

export default function tableScroll() {
  return {
    name: 'table-scroll',
    hooks: {
      'astro:build:done': async ({ dir, logger }) => {
        const files = await walk(path.join(dir.pathname, 'learn'));
        let wrapped = 0;
        let pages = 0;

        for (const file of files) {
          const html = await readFile(file, 'utf8');
          let out = '';
          let cursor = 0;
          let count = 0;

          // Tables do not nest in Markdown output, so matching each opening tag
          // to the next closing one is safe here.
          const opens = [...html.matchAll(/<table\b/g)];
          for (const open of opens) {
            const start = open.index;
            const end = html.indexOf('</table>', start);
            if (end === -1) continue;
            const stop = end + '</table>'.length;

            const before = html.slice(cursor, start);
            if (ALREADY_WRAPPED.test(before)) {
              out += before + html.slice(start, stop);
            } else {
              out += before + '<div class="table-scroll">' + html.slice(start, stop) + '</div>';
              count += 1;
            }
            cursor = stop;
          }

          if (count === 0) continue;
          out += html.slice(cursor);
          await writeFile(file, out);
          wrapped += count;
          pages += 1;
        }

        logger.info(`wrapped ${wrapped} table(s) across ${pages} page(s)`);
      },
    },
  };
}
