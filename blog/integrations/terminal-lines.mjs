/**
 * Marks the "$ command" line inside a captured terminal block.
 *
 * Every capture in the learn track has the same shape: a `# distro, arch`
 * comment, one `$ command` line, then whatever the command printed. Shiki
 * colours the whole block with the bash grammar, so the command and its output
 * end up looking alike even though only one of them is a thing you would type.
 * This tags the command so CSS can set it apart.
 *
 * It runs after the build rather than as a rehype plugin because this Astro
 * version does not use the unified processor by default, and switching the
 * whole site's Markdown pipeline to get one class added is not a trade worth
 * making: the topics lean on CommonMark's raw-HTML block behaviour for their
 * <details>, <dl> and <figure> markup, and that is exactly the sort of thing a
 * processor change alters quietly.
 *
 * Shiki emits one `<span class="line">` per source line, newline separated, so
 * the transform is a line-oriented pass: strip the tags off a line, and if what
 * is left starts with "$ ", add the class. A block with no prompt line, a YAML
 * or Dockerfile sample for instance, is left exactly as it was.
 */
import { readFile, writeFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const LINE_OPEN = '<span class="line">';

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

/** Visible text of one Shiki line: tags removed, the few entities decoded. */
function visibleText(html) {
  return html
    .replace(/<[^>]*>/g, '')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&');
}

export default function terminalLines() {
  return {
    name: 'terminal-lines',
    hooks: {
      'astro:build:done': async ({ dir, logger }) => {
        const root = fileURLToPath(dir);
        const files = await walk(root);
        let marked = 0;
        let touched = 0;
        for (const file of files) {
          const html = await readFile(file, 'utf8');
          if (!html.includes(LINE_OPEN)) continue;
          let hits = 0;
          const next = html
            .split('\n')
            .map((line) => {
              if (!line.startsWith(LINE_OPEN)) return line;
              if (!visibleText(line).startsWith('$ ')) return line;
              hits += 1;
              return '<span class="line cmd">' + line.slice(LINE_OPEN.length);
            })
            .join('\n');
          if (hits === 0) continue;
          await writeFile(file, next);
          marked += hits;
          touched += 1;
        }
        logger.info(`marked ${marked} command lines across ${touched} pages`);
      },
    },
  };
}
