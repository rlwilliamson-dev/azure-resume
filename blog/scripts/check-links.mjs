#!/usr/bin/env node
/**
 * Fetch every URL in every `sources` array in the learn content and report the
 * ones that no longer resolve.
 *
 * Citations rot. A topic that cites a Red Hat page which has since moved is
 * worse than one that cites nothing, because it looks checked. This finds that
 * before a reader does.
 *
 * Deliberately NOT part of `npm run build`. A third party's outage should never
 * block a deploy. Run it on a schedule, or by hand:
 *
 *   npm run check:links
 *   npm run check:links -- --track linux-plus
 *
 * Exits 1 if any URL fails, so a scheduled job can surface it.
 */
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const contentDir = path.join(root, 'src/content/learn');

const TIMEOUT_MS = 20000;
const CONCURRENCY = 6;
// Some documentation hosts reject requests without a browser-shaped UA.
const UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';

const trackFilter = (() => {
  const i = process.argv.indexOf('--track');
  return i !== -1 ? process.argv[i + 1] : null;
})();

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
    else if (entry.name.endsWith('.md') && !entry.name.startsWith('_')) out.push(full);
  }
  return out;
}

/**
 * Pull the `url:` values out of a file's frontmatter. `url` only appears inside
 * `sources` entries, so matching it directly avoids pulling in a YAML parser
 * for one field.
 */
function urlsIn(text) {
  const fence = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!fence) return [];
  return [...fence[1].matchAll(/^\s*-?\s*url:\s*["']?(https?:\/\/[^"'\s]+)["']?\s*$/gm)].map(
    (m) => m[1]
  );
}

async function check(url) {
  const attempt = async (method) => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
    try {
      const res = await fetch(url, {
        method,
        redirect: 'follow',
        signal: controller.signal,
        headers: { 'user-agent': UA, accept: '*/*' },
      });
      return { status: res.status, url: res.url };
    } finally {
      clearTimeout(timer);
    }
  };

  try {
    // HEAD first; a fair number of doc hosts answer 403 or 405 to it, so fall
    // back to GET before calling a link dead.
    let result = await attempt('HEAD');
    if (result.status >= 400) result = await attempt('GET');
    return result;
  } catch (err) {
    return { status: 0, error: err.name === 'AbortError' ? 'timeout' : String(err.message ?? err) };
  }
}

/**
 * Hosts that serve an anti-bot interstitial to anything without a real browser.
 * freedesktop answers 418 with "Checking you are not a bot"; the others answer
 * 403 or a challenge page. The citations behind them are fine, and reporting
 * them as failures trains everyone to ignore this script, so they are reported
 * separately as unverified rather than counted as broken.
 *
 * Unverified is not the same as verified. Anything listed here needs a human to
 * open it occasionally, which is the cost of citing a host that blocks robots.
 */
const BOT_WALLED = [
  'www.freedesktop.org',
  'net-snmp.sourceforge.io',
  'wiki.debian.org',
  'www.smartmontools.org',
  'en.opensuse.org',
  'docs.redhat.com',
];

const botWalled = (url) => {
  try {
    return BOT_WALLED.includes(new URL(url).host);
  } catch {
    return false;
  }
};

const files = (await walk(contentDir)).filter(
  (f) => !trackFilter || path.relative(contentDir, f).split(path.sep)[0] === trackFilter
);

/** One entry per (file, url) so a failure names the file that has to be fixed. */
const targets = [];
for (const file of files) {
  const text = await readFile(file, 'utf8');
  for (const url of urlsIn(text)) {
    targets.push({ file: path.relative(root, file), url });
  }
}

if (targets.length === 0) {
  console.log(
    `No source URLs found${trackFilter ? ` in track "${trackFilter}"` : ''}. Nothing to check.`
  );
  process.exit(0);
}

console.log(`Checking ${targets.length} source URL${targets.length === 1 ? '' : 's'}...\n`);

const failures = [];
const unverified = [];
let done = 0;

// Cache by URL so the same citation reused across topics is fetched once.
const cache = new Map();

async function worker(queue) {
  for (;;) {
    const target = queue.shift();
    if (!target) return;
    if (!cache.has(target.url)) cache.set(target.url, check(target.url));
    const result = await cache.get(target.url);
    done += 1;
    const ok = result.status >= 200 && result.status < 400;
    if (!ok && botWalled(target.url)) {
      unverified.push({ ...target, ...result });
    } else if (!ok) {
      failures.push({ ...target, ...result });
      console.log(`  FAIL ${String(result.status || result.error).padEnd(8)} ${target.url}`);
    }
    if (done % 20 === 0) console.log(`  ...${done}/${targets.length}`);
  }
}

const queue = [...targets];
await Promise.all(Array.from({ length: CONCURRENCY }, () => worker(queue)));

console.log(`\nChecked ${done} URL${done === 1 ? '' : 's'}, ${failures.length} failing.`);

if (unverified.length > 0) {
  const hosts = [...new Set(unverified.map((u) => new URL(u.url).host))].sort();
  console.log(
    `${unverified.length} could not be checked because the host blocks robots ` +
      `(${hosts.join(', ')}). Open those by hand now and then.`
  );
}

if (failures.length > 0) {
  console.log('\nBroken citations:\n');
  for (const f of failures) {
    console.log(`  ${f.file}`);
    console.log(`    ${f.url}`);
    console.log(`    ${f.error ? `error: ${f.error}` : `HTTP ${f.status}`}\n`);
  }
  process.exit(1);
}
