/**
 * Route coverage for the built static output.
 *
 * Uses the Node built-in test runner, so there is no test framework dependency
 * to keep current. It asserts against dist rather than importing modules,
 * because what matters here is the set of files that actually ship: the shape
 * of the URL surface, that drafts stayed out, and that adding /learn did not
 * disturb anything the blog was already serving.
 *
 * Run `npm run build` first. CI does exactly that, then runs this before the
 * deploy step, so a route regression fails the deploy.
 */
import { test, describe, before } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.join(root, 'dist');

const read = (rel) => readFileSync(path.join(dist, rel), 'utf8');
const has = (rel) => existsSync(path.join(dist, rel));

before(() => {
  assert.ok(
    existsSync(dist),
    'dist/ not found. Run "npm run build" before "npm test".'
  );
});

describe('existing blog routes are unaffected', () => {
  // The full public URL surface of the blog before /learn was added. If a
  // change to the shared layout or the base path drops one of these, this is
  // where it surfaces.
  const BLOG_ROUTES = [
    'blog/index.html',
    'blog/cloud-resume-challenge/index.html',
    'blog/hello-world/index.html',
    'blog/tags/index.html',
    'blog/tags/azure/index.html',
    'blog/tags/bicep/index.html',
    'blog/tags/cloud-resume-challenge/index.html',
    'blog/tags/cosmos-db/index.html',
    'blog/tags/devops/index.html',
    'blog/tags/github-actions/index.html',
    'blog/tags/iac/index.html',
    'blog/tags/meta/index.html',
    'blog/tags/static-web-apps/index.html',
  ];

  for (const route of BLOG_ROUTES) {
    test(`/${route.replace(/index\.html$/, '')} still builds`, () => {
      assert.ok(has(route), `missing ${route}`);
    });
  }

  test('blog internal links still point under /blog', () => {
    const html = read('blog/index.html');
    assert.match(html, /href="\/blog\/cloud-resume-challenge"/);
    assert.match(html, /href="\/blog\/tags"/);
    assert.match(html, /href="\/blog\/rss\.xml"/);
  });

  test('rss feed exists and carries absolute /blog links', () => {
    assert.ok(has('blog/rss.xml'), 'missing blog/rss.xml');
    const xml = read('blog/rss.xml');
    // Trailing slash included: this is the exact shape the feed had before the
    // learn section was added, verified by diffing against a baseline build.
    assert.match(xml, /<link>https:\/\/rlwilliamson\.dev\/blog\/cloud-resume-challenge\/<\/link>/);
    assert.match(xml, /<link>https:\/\/rlwilliamson\.dev\/blog\/hello-world\/<\/link>/);
    assert.match(xml, /<title>Ryan Williamson Blog<\/title>/);
    // Learn topics are a separate section and must not leak into the blog feed.
    assert.doesNotMatch(xml, /\/learn\//);
  });

  test('shared assets are emitted at the site root, not under /blog', () => {
    const html = read('blog/index.html');
    assert.match(html, /href="\/_astro\//, 'stylesheet should be linked from /_astro');
    assert.doesNotMatch(html, /href="\/blog\/_astro\//);
  });
});

describe('learn routes', () => {
  test('landing page builds and lists tracks', () => {
    assert.ok(has('learn/index.html'));
    const html = read('learn/index.html');
    assert.match(html, /href="\/learn\/bicep"/);
    assert.match(html, /href="\/learn\/security-plus"/);
  });

  test('track index builds from the directory name', () => {
    assert.ok(has('learn/bicep/index.html'));
    const html = read('learn/bicep/index.html');
    assert.match(html, /href="\/learn\/bicep\/modules-and-scopes"/);
  });

  test('topic page builds with the ordering prefix stripped from the URL', () => {
    assert.ok(
      has('learn/bicep/modules-and-scopes/index.html'),
      'expected 01-modules-and-scopes.md to publish at /learn/bicep/modules-and-scopes'
    );
    assert.ok(!has('learn/bicep/01-modules-and-scopes/index.html'));
  });

  test('topic page carries the frontmatter surface', () => {
    const html = read('learn/bicep/modules-and-scopes/index.html');
    assert.match(html, /Working knowledge/, 'level should be rendered');
    assert.match(html, /What you will be able to do/, 'objectives block should render');
    assert.match(html, /Explain what targetScope controls/, 'objective text should render');
    assert.match(html, /updated/, 'updated date should render');
  });

  test('topic page has sidebar navigation and on-page contents', () => {
    const html = read('learn/bicep/modules-and-scopes/index.html');
    assert.match(html, /class="learn-nav-list"/, 'sidebar list missing');
    assert.match(html, /aria-current="page"/, 'current topic should be marked');
    assert.match(html, /learn-toc|On this page/, 'table of contents missing');
  });

  test('code blocks are highlighted for the languages the notes use', () => {
    const html = read('learn/bicep/modules-and-scopes/index.html');
    assert.match(html, /data-language="bicep"/, 'bicep block not highlighted');
    assert.match(html, /data-language="bash"/, 'bash block not highlighted');
    assert.match(html, /class="astro-code/, 'shiki output missing');
  });
});

describe('drafts and templates stay out of the production build', () => {
  test('the authoring template does not publish', () => {
    assert.ok(!has('learn/_template/index.html'));
    assert.ok(!has('learn/template/index.html'));
  });

  test('no page in the build is marked draft', async () => {
    const pages = await walk(path.join(dist, 'learn'));
    for (const page of pages) {
      const html = readFileSync(page, 'utf8');
      assert.ok(
        !html.includes('class="draft-badge"'),
        `${path.relative(dist, page)} renders a draft badge, so a draft reached the production build`
      );
    }
  });
});

describe('practice engine', () => {
  test('a bank file creates a practice route', () => {
    assert.ok(has('learn/security-plus/practice/fundamentals/index.html'));
  });

  test('the track index links to its practice sets', () => {
    const html = read('learn/security-plus/index.html');
    assert.match(html, /href="\/learn\/security-plus\/practice\/fundamentals"/);
  });

  test('questions ship as data, with real inputs built from them', () => {
    const html = read('learn/security-plus/practice/fundamentals/index.html');
    assert.match(html, /type="application\/json" data-quiz-bank/);
    assert.match(html, /sp-001/, 'question data should be embedded');
    assert.match(html, /name="quiz-mode"/, 'mode selection should use real radios');
    assert.match(html, /<fieldset class="quiz-mode">/, 'mode selection should be a fieldset');
  });

  test('the bank validates against the schema', async () => {
    const bank = JSON.parse(
      readFileSync(path.join(root, 'src/data/quizzes/security-plus/fundamentals.json'), 'utf8')
    );
    assert.ok(bank.questions.length > 0);
    for (const q of bank.questions) {
      const ids = q.options.map((o) => o.id);
      assert.ok(q.correct.length >= 1, `${q.id} has no correct answer`);
      assert.ok(q.correct.length < q.options.length, `${q.id} marks every option correct`);
      assert.ok(q.explanation.length > 0, `${q.id} has no explanation`);
      assert.ok(q.domain.length > 0, `${q.id} has no domain`);
      for (const c of q.correct) {
        assert.ok(ids.includes(c), `${q.id} marks unknown option "${c}" correct`);
      }
    }
    const multi = bank.questions.filter((q) => q.correct.length > 1);
    assert.ok(multi.length > 0, 'bank should exercise multiple-answer questions');
  });
});

describe('search index', () => {
  test('pagefind output lands in the deployed directory', () => {
    assert.ok(has('pagefind/pagefind.js'), 'pagefind entry script missing from dist');
    assert.ok(has('pagefind/pagefind-entry.json'), 'pagefind index metadata missing');
  });

  test('the index covers learn topics and nothing else', () => {
    const entry = JSON.parse(read('pagefind/pagefind-entry.json'));
    const languages = Object.values(entry.languages ?? {});
    const indexed = languages.reduce((sum, lang) => sum + (lang.page_count ?? 0), 0);
    assert.ok(indexed > 0, 'pagefind indexed nothing');

    // data-pagefind-body is only on learn topic pages, so the count should
    // track topics rather than every page in the build.
    assert.ok(indexed <= 5, `expected only learn topics to be indexed, got ${indexed} pages`);
  });

  test('a track filter is available for scoped search', async () => {
    const filters = await walk(path.join(dist, 'pagefind'), /\.pf_filter$/);
    assert.ok(
      filters.length > 0,
      'expected a filter index, which is what data-pagefind-filter="track:..." produces'
    );
  });
});

describe('images in learn content are optimized', () => {
  test('no learn page references an unprocessed image', async () => {
    const pages = await walk(path.join(dist, 'learn'));
    for (const page of pages) {
      const html = readFileSync(page, 'utf8');
      for (const [, src] of html.matchAll(/<img[^>]*\ssrc="([^"]+)"/g)) {
        if (src.startsWith('data:')) continue;
        assert.ok(
          src.startsWith('/_astro/'),
          `${path.relative(dist, page)} references "${src}", which did not go through the image pipeline`
        );
      }
    }
  });

  test('every learn image declares width, height, and lazy loading', async () => {
    const pages = await walk(path.join(dist, 'learn'));
    for (const page of pages) {
      const html = readFileSync(page, 'utf8');
      for (const [tag] of html.matchAll(/<img[^>]*>/g)) {
        assert.match(tag, /\swidth="\d+"/, `missing width in ${path.relative(dist, page)}`);
        assert.match(tag, /\sheight="\d+"/, `missing height in ${path.relative(dist, page)}`);
        assert.match(tag, /\sloading="(lazy|eager)"/, `missing loading in ${path.relative(dist, page)}`);
      }
    }
  });

  test('raster images are offered as AVIF with a fallback', async () => {
    const pages = await walk(path.join(dist, 'learn'));
    for (const page of pages) {
      const html = readFileSync(page, 'utf8');
      for (const [tag, src] of html.matchAll(/<img[^>]*\ssrc="([^"]+\.(?:png|jpe?g|webp))"/g)) {
        const index = html.indexOf(tag);
        const preceding = html.slice(Math.max(0, index - 200), index);
        assert.match(
          preceding,
          /<source type="image\/avif"/,
          `${src} in ${path.relative(dist, page)} is not wrapped in a picture with an AVIF source`
        );
      }
    }
  });
});

describe('house style', () => {
  // The site copy is deliberately ASCII. This guards the files added for the
  // learn section; it does not police pre-existing blog components.
  const SCOPED = [
    'src/content/learn',
    'src/pages/learn',
    'src/components/learn',
    'src/lib',
    'src/config',
    'src/data',
    'integrations',
  ];

  test('no emoji or Unicode arrows in learn source', async () => {
    const offenders = [];
    // Arrows, dingbats, emoji blocks, and the miscellaneous symbols range.
    const banned = /[←-⇿✀-➿☀-⛿️\u{1F000}-\u{1FAFF}]/u;

    for (const dir of SCOPED) {
      const abs = path.join(root, dir);
      if (!existsSync(abs)) continue;
      for (const file of await walk(abs, /\.(md|ts|astro|mjs|json)$/)) {
        const text = readFileSync(file, 'utf8');
        text.split('\n').forEach((line, i) => {
          const hit = line.match(banned);
          if (hit) offenders.push(`${path.relative(root, file)}:${i + 1} contains "${hit[0]}"`);
        });
      }
    }

    assert.deepEqual(offenders, [], `non-ASCII symbols found:\n${offenders.join('\n')}`);
  });
});

/** Recursively collect files under dir, optionally filtered by extension. */
async function walk(dir, match = /\.html$/) {
  const out = [];
  let entries;
  try {
    entries = await readdir(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...(await walk(full, match)));
    else if (match.test(entry.name)) out.push(full);
  }
  return out;
}
