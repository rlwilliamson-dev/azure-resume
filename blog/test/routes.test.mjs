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

  test('headings render as tokenized terminal lines with an accessible name', () => {
    const blog = read('blog/index.html');
    // The command is split into coloured tokens rather than left as one string.
    assert.match(blog, /class="term-heading-cmd">ls</);
    assert.match(blog, /class="term-heading-flag">-t</);
    assert.match(blog, /class="term-heading-path">\/blog</);
    // The visible line is decorative; the heading's accessible name is a word.
    assert.match(blog, /<h1 class="term-heading" aria-label="Blog">/);
    assert.match(blog, /aria-hidden="true"/);

    // Quoted arguments tokenize as strings, not paths.
    const tag = read('blog/tags/azure/index.html');
    assert.match(tag, /class="term-heading-str">&quot;#azure&quot;</);
    assert.match(tag, /aria-label="Posts tagged azure"/);
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
    assert.match(html, /href="\/learn\/network-plus"/);
    assert.match(html, /href="\/learn\/linux-plus"/);
    assert.match(html, /<h1 class="term-heading" aria-label="Learn">/);
  });

  test('track index heading is derived from the track, not hardcoded', () => {
    const html = read('learn/bicep/index.html');
    assert.match(html, /class="term-heading-path">\/learn\/bicep</);
    assert.match(html, /aria-label="Bicep"/);
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

describe('weighted exam sampling', () => {
  /**
   * Pull the serialized quiz config out of a built exam page. It is JSON inside
   * a script tag, HTML-escaped by Astro on the way in.
   */
  function examConfig(track) {
    const html = read(`learn/${track}/exam/index.html`);
    const match = html.match(/data-quiz-config[^>]*>([\s\S]*?)<\/script>/);
    assert.ok(match, `no quiz config embedded on the ${track} exam page`);
    const json = match[1]
      .replace(/&quot;/g, '"')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&amp;/g, '&');
    return JSON.parse(json).exam;
  }

  /**
   * Rounding each domain weight on its own does not reliably total the exam
   * length. XK0-006 happens to round to exactly 90 and N10-009 rounds to 91, so
   * this only bites when a second exam arrives. Assert the property rather than
   * the numbers, so it holds for whatever exam is added next.
   */
  for (const track of ['linux-plus']) {
    test(`${track}: domain shares total the exam length`, () => {
      const exam = examConfig(track);
      const total = exam.domains.reduce((sum, d) => sum + d.share, 0);
      assert.equal(
        total,
        exam.questionCount,
        `shares ${exam.domains.map((d) => `${d.id}=${d.share}`).join(' ')} total ${total}, but ${exam.code} is ${exam.questionCount} questions`
      );
    });

    test(`${track}: every domain is within one question of its exact share`, () => {
      const exam = examConfig(track);
      for (const domain of exam.domains) {
        const exact = (domain.weight / 100) * exam.questionCount;
        assert.ok(
          Math.abs(domain.share - exact) < 1,
          `${domain.id} has ${domain.share} against an exact share of ${exact}`
        );
      }
    });
  }
});

describe('search index', () => {
  test('pagefind output lands in the deployed directory', () => {
    assert.ok(has('pagefind/pagefind.js'), 'pagefind entry script missing from dist');
    assert.ok(has('pagefind/pagefind-entry.json'), 'pagefind index metadata missing');
  });

  test('the index covers learn topics and nothing else', async () => {
    const entry = JSON.parse(read('pagefind/pagefind-entry.json'));
    const languages = Object.values(entry.languages ?? {});
    const indexed = languages.reduce((sum, lang) => sum + (lang.page_count ?? 0), 0);
    assert.ok(indexed > 0, 'pagefind indexed nothing');

    // data-pagefind-body marks the content column on topic pages and nothing
    // else, so the indexed count should equal the number of pages carrying it.
    // Counting them rather than asserting a ceiling means adding a topic never
    // breaks this test, while a stray marker on a non-topic page still does.
    const pages = await walk(path.join(dist, 'learn'));
    const marked = pages.filter((page) =>
      readFileSync(page, 'utf8').includes('data-pagefind-body')
    );

    assert.equal(
      indexed,
      marked.length,
      `pagefind indexed ${indexed} pages but ${marked.length} carry data-pagefind-body. ` +
        'A mismatch means either a non-topic page is being indexed or a topic is missing from the index.'
    );

    // The marker must not have leaked onto the generated pages, which are
    // navigation rather than content.
    for (const generated of ['coverage', 'plan', 'exam']) {
      const page = path.join(dist, 'learn', 'linux-plus', generated, 'index.html');
      if (existsSync(page)) {
        assert.ok(
          !readFileSync(page, 'utf8').includes('data-pagefind-body'),
          `${generated} is a generated page and should not be indexed as content`
        );
      }
    }
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

  test('no emoji or Unicode arrows in learn prose', async () => {
    const offenders = [];
    // Arrows, dingbats, emoji blocks, and the miscellaneous symbols range.
    const banned = /[←-⇿✀-➿☀-⛿️\u{1F000}-\u{1FAFF}]/u;

    for (const dir of SCOPED) {
      const abs = path.join(root, dir);
      if (!existsSync(abs)) continue;
      for (const file of await walk(abs, /\.(md|ts|astro|mjs|json)$/)) {
        const text = readFileSync(file, 'utf8');
        // Fenced blocks are exempt. The rule is about how we write, and
        // captured output is not written: systemd prints an arrow when it
        // creates a symlink and hostnamectl prints a chassis glyph. Retyping
        // those to satisfy a style rule would falsify a transcript, which is
        // a worse sin than an arrow.
        let inFence = false;
        text.split('\n').forEach((line, i) => {
          if (/^\s*```/.test(line)) {
            inFence = !inFence;
            return;
          }
          if (inFence) return;
          const hit = line.match(banned);
          if (hit) offenders.push(`${path.relative(root, file)}:${i + 1} contains "${hit[0]}"`);
        });
      }
    }

    assert.deepEqual(offenders, [], `non-ASCII symbols found:\n${offenders.join('\n')}`);
  });
});

/**
 * A blank line means opposite things in the two kinds of figure on this site,
 * which is why each kind gets its own rule below.
 *
 * A blank line inside a raw HTML block ends that block. In a figure holding an
 * inline SVG that is fatal: everything after the blank line is re-parsed as
 * Markdown and the rest of the diagram is dropped, leaving a page that still
 * renders with half a picture on it.
 *
 * In a figure holding a photograph it is mandatory, and for the same reason.
 * The image is written as Markdown so that Astro resolves the relative path and
 * runs the file through the image pipeline, and Markdown inside a raw HTML block
 * is not parsed at all. The blank line is what closes the block and gets the
 * image seen. Without it the page ships the literal text of the image syntax.
 */
const LEARN_FIGURE = /<figure class="learn-figure[^"]*">[\s\S]*?<\/figure>/g;
const MARKDOWN_IMAGE = /!\[[^\]]*\]\(\.\/images\/[^)]+\)/;

describe('inline diagrams survive Markdown', () => {
  test('no blank lines inside a figure holding an SVG', async () => {
    const offenders = [];

    for (const file of await walk(path.join(root, 'src/content/learn'), /\.md$/)) {
      const text = readFileSync(file, 'utf8');
      for (const match of text.matchAll(LEARN_FIGURE)) {
        if (!match[0].includes('<svg')) continue;
        const before = text.slice(0, match.index).split('\n').length;
        match[0].split('\n').forEach((line, i) => {
          if (line.trim() === '') {
            offenders.push(`${path.relative(root, file)}:${before + i} blank line inside <figure>`);
          }
        });
      }
    }

    assert.deepEqual(
      offenders,
      [],
      `a blank line here truncates the diagram at build time:\n${offenders.join('\n')}`
    );
  });

  test('every built diagram carries all of its shapes', async () => {
    // Compare the shape count in the source against the shape count in the
    // built HTML. A truncated block loses elements, and nothing else does.
    const shapes = /<(rect|circle|path|line|polyline|polygon|text)\b/g;
    const built = new Map();
    for (const file of await walk(path.join(root, 'dist/learn'))) {
      built.set(file, readFileSync(file, 'utf8'));
    }

    const offenders = [];
    for (const file of await walk(path.join(root, 'src/content/learn'), /\.md$/)) {
      const text = readFileSync(file, 'utf8');
      const source = [...text.matchAll(LEARN_FIGURE)].filter((m) => m[0].includes('<svg'));
      if (source.length === 0) continue;

      const slug = path.basename(file, '.md').replace(/^\d+-/, '');
      const page = [...built.entries()].find(([p]) => p.includes(`${path.sep}${slug}${path.sep}`));
      if (!page) continue;

      const expected = source.reduce((n, m) => n + (m[0].match(shapes) || []).length, 0);
      const actual = [...page[1].matchAll(LEARN_FIGURE)]
        .filter((m) => m[0].includes('<svg'))
        .reduce((n, m) => n + (m[0].match(shapes) || []).length, 0);

      if (actual < expected) {
        offenders.push(`${slug}: ${actual} of ${expected} shapes reached the page`);
      }
    }

    assert.deepEqual(offenders, [], `diagrams truncated at build time:\n${offenders.join('\n')}`);
  });

  test('every photograph is surrounded by the blank lines that make it an image', async () => {
    const offenders = [];

    for (const file of await walk(path.join(root, 'src/content/learn'), /\.md$/)) {
      const text = readFileSync(file, 'utf8');
      for (const match of text.matchAll(LEARN_FIGURE)) {
        if (!MARKDOWN_IMAGE.test(match[0])) continue;
        const before = text.slice(0, match.index).split('\n').length;
        const lines = match[0].split('\n');
        lines.forEach((line, i) => {
          if (!MARKDOWN_IMAGE.test(line)) return;
          const opens = lines[i - 1] !== undefined && lines[i - 1].trim() === '';
          const closes = lines[i + 1] !== undefined && lines[i + 1].trim() === '';
          if (!opens || !closes) {
            offenders.push(
              `${path.relative(root, file)}:${before + i} image needs a blank line on both sides`
            );
          }
        });
      }
    }

    assert.deepEqual(
      offenders,
      [],
      `without the blank lines the page ships the Markdown source:\n${offenders.join('\n')}`
    );
  });

  test('no built page ships the source text of an image instead of the image', async () => {
    const offenders = [];
    for (const file of await walk(path.join(root, 'dist/learn'))) {
      if (readFileSync(file, 'utf8').includes('](./images/')) {
        offenders.push(path.relative(root, file));
      }
    }
    assert.deepEqual(offenders, [], `unrendered image syntax on:\n${offenders.join('\n')}`);
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

/**
 * Every photograph on this site is somebody else's work used under a licence
 * that requires attribution. The credit is therefore not a nicety, it is the
 * condition of use, and it lives in two places: images/credits.json records
 * what the file is and where it came from, and the topic's References section
 * carries the visible credit a reader can follow.
 *
 * Both can drift silently. A photograph added without a credit looks perfect on
 * the page, and a credit left behind after its photograph is removed looks
 * perfect too. So the manifest and the pages are checked against each other and
 * against the files actually on disk.
 */
describe('photograph credits', () => {
  const manifests = async () => {
    const found = [];
    for (const file of await walk(path.join(root, 'src/content/learn'), /^credits\.json$/)) {
      found.push({ dir: path.dirname(file), data: JSON.parse(readFileSync(file, 'utf8')) });
    }
    return found;
  };

  test('every committed image is described in the manifest', async () => {
    const offenders = [];
    for (const { dir, data } of await manifests()) {
      const files = (await readdir(dir)).filter((n) => /\.(jpe?g|png|webp|avif)$/i.test(n));
      for (const file of files) {
        if (!data.images[file]) offenders.push(`${path.relative(root, path.join(dir, file))}`);
      }
      for (const named of Object.keys(data.images)) {
        if (!files.includes(named)) {
          offenders.push(`${path.relative(root, dir)}/${named} is credited but not committed`);
        }
      }
    }
    assert.deepEqual(offenders, [], `missing from credits.json:\n${offenders.join('\n')}`);
  });

  test('every credited image names an author and a licence', async () => {
    const offenders = [];
    for (const { data } of await manifests()) {
      for (const [file, record] of Object.entries(data.images)) {
        for (const field of ['topic', 'source', 'author', 'licence']) {
          if (!record[field]) offenders.push(`${file} has no ${field}`);
        }
        if (record.licence && record.licence !== 'Public domain' && !record.licenceUrl) {
          offenders.push(`${file} is under ${record.licence} and has no link to the licence`);
        }
      }
    }
    assert.deepEqual(offenders, [], `incomplete credits:\n${offenders.join('\n')}`);
  });

  test('the page using an image links back to where it came from', async () => {
    const offenders = [];
    for (const { data } of await manifests()) {
      for (const [file, record] of Object.entries(data.images)) {
        const slug = record.topic.replace(/^\d+-/, '');
        const page = [...(await walk(path.join(root, 'dist/learn')))].find((p) =>
          p.includes(`${path.sep}${slug}${path.sep}`)
        );
        if (!page) {
          offenders.push(`${file} names topic "${record.topic}", which did not build`);
          continue;
        }
        const html = readFileSync(page, 'utf8');
        // Compare on the Commons file name rather than the whole URL, and allow
        // either the percent-encoded or the plain form: a title containing a
        // character like "+" is legal in both and the two are the same file.
        const encoded = record.source.split('/').pop();
        const forms = [encoded, decodeURIComponent(encoded)].map((f) => f.replace(/&/g, '&#38;'));
        if (!forms.some((f) => html.includes(f))) {
          offenders.push(`${slug} shows ${file} without linking to ${forms[1]}`);
        }
        if (record.author && !html.includes(record.author)) {
          offenders.push(`${slug} shows ${file} without naming ${record.author}`);
        }
      }
    }
    assert.deepEqual(offenders, [], `uncredited images on built pages:\n${offenders.join('\n')}`);
  });
});

describe('beyond the exam material', () => {
  /**
   * Topics marked `beyondExam` are the off-syllabus half of a certification
   * track. The rule they exist under is that a reader revising for a date can
   * tell at a glance which pages are not on the exam, so all three of these
   * have to hold at once: they sit in their own section, they do not consume a
   * lesson number, and nothing in the practice banks sends anybody to one.
   */
  const beyondTopics = async () => {
    const found = [];
    for (const file of await walk(path.join(root, 'src/content/learn'), /\.md$/)) {
      const src = readFileSync(file, 'utf8');
      const fm = src.split('---')[1] ?? '';
      if (!/^beyondExam:\s*true\s*$/m.test(fm)) continue;
      const rel = path.relative(path.join(root, 'src/content/learn'), file);
      const [track, name] = rel.split(path.sep);
      found.push({ track, slug: name.replace(/^\d+[-_]/, '').replace(/\.md$/, '') });
    }
    return found;
  };

  test('each one is listed under its own heading, not among the lessons', async () => {
    const offenders = [];
    for (const { track, slug } of await beyondTopics()) {
      const html = read(`learn/${track}/index.html`);
      const split = html.indexOf('id="beyond-heading"');
      const link = html.indexOf(`href="/learn/${track}/${slug}"`);
      if (split === -1) {
        offenders.push(`${track}: no "Beyond the exam" section on the track index`);
      } else if (link === -1) {
        offenders.push(`${track}/${slug}: not linked from the track index at all`);
      } else if (link < split) {
        offenders.push(`${track}/${slug}: listed among the lessons rather than after the split`);
      }
    }
    assert.deepEqual(offenders, [], offenders.join('\n'));
  });

  test('none of them takes a lesson number', async () => {
    const offenders = [];
    for (const { track, slug } of await beyondTopics()) {
      const html = read(`learn/${track}/${slug}/index.html`);
      if (/Lesson\s+\d+\s+of\s+\d+/.test(html)) {
        offenders.push(`${track}/${slug} claims a lesson number`);
      }
      if (!html.includes('Beyond the exam')) {
        offenders.push(`${track}/${slug} does not say it is beyond the exam`);
      }
    }
    assert.deepEqual(offenders, [], offenders.join('\n'));
  });

  test('no practice question points at one', async () => {
    const beyond = new Set((await beyondTopics()).map((t) => `${t.track}/${t.slug}`));
    if (beyond.size === 0) return;
    const offenders = [];
    for (const file of await walk(path.join(root, 'src/data/quizzes'), /\.json$/)) {
      const track = path.basename(path.dirname(file));
      const bank = JSON.parse(readFileSync(file, 'utf8'));
      for (const q of bank.questions ?? []) {
        if (!q.learnRef) continue;
        const key = q.learnRef.includes('/') ? q.learnRef : `${track}/${q.learnRef}`;
        if (beyond.has(key)) offenders.push(`${q.id} links to off-syllabus "${key}"`);
      }
    }
    assert.deepEqual(offenders, [], offenders.join('\n'));
  });
});

/**
 * A track being written stays off the public site.
 *
 * A track appears the moment it has one topic or one question bank, which is
 * right for a track about to be finished and wrong for one page of an eventual
 * eighty. `hidden` in src/config/tracks.ts turns that off, and "off the site"
 * has to mean four separate things or it means very little: not on the listing,
 * not in the sitemap, not indexable, and not in the site's own search.
 *
 * The pages still build. This is unlisted rather than unpublished, so a URL
 * somebody already has keeps working and a preview deploy stays reviewable.
 * That distinction is the reason the filter sits on the listing rather than on
 * getLearnTracks: filtering there took the whole track's routes out with it,
 * including the coverage page the author uses to see what is left.
 */
describe('tracks kept off the public site', () => {
  const HIDDEN = ['bicep', 'security-plus'];
  const VISIBLE = ['network-plus', 'linux-plus'];

  test('the config and the test agree on which tracks are hidden', () => {
    // Reading the source rather than importing it, because the tests are plain
    // JavaScript and the config is TypeScript. A slug changing state without
    // this list changing should fail here rather than quietly stop being tested.
    const config = readFileSync(path.join(root, 'src/config/tracks.ts'), 'utf8');
    const declared = [...config.matchAll(/'?([a-z-]+)'?:\s*\{[^}]*?hidden:\s*true/gs)].map(
      (m) => m[1]
    );
    assert.deepEqual(
      declared.sort(),
      [...HIDDEN].sort(),
      'TRACK_META hidden flags do not match the list in this test'
    );
  });

  test('a hidden track is not on the learn landing page', () => {
    const html = read('learn/index.html');
    for (const slug of HIDDEN) {
      assert.ok(
        !html.includes(`href="/learn/${slug}"`),
        `${slug} is marked hidden and is still linked from /learn`
      );
    }
    for (const slug of VISIBLE) {
      assert.match(html, new RegExp(`href="/learn/${slug}"`));
    }
  });

  test('a hidden track is not in the sitemap', () => {
    const xml = read('sitemap-0.xml');
    const locs = [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1]);
    for (const slug of HIDDEN) {
      const leaked = locs.filter((u) => new URL(u).pathname.startsWith(`/learn/${slug}`));
      assert.deepEqual(leaked, [], `${slug} pages are in the sitemap`);
    }
    // And the visible tracks still are, so an over-broad filter is caught too.
    for (const slug of VISIBLE) {
      assert.ok(
        locs.some((u) => new URL(u).pathname.startsWith(`/learn/${slug}`)),
        `${slug} is missing from the sitemap`
      );
    }
  });

  test('every page of a hidden track asks not to be indexed', async () => {
    for (const slug of HIDDEN) {
      const dir = path.join(dist, 'learn', slug);
      if (!existsSync(dir)) continue;
      const pages = await walk(dir);
      assert.ok(pages.length > 0, `${slug} built no pages, so hiding it unpublished it`);
      for (const page of pages) {
        assert.match(
          readFileSync(page, 'utf8'),
          /name="robots" content="noindex/,
          `${path.relative(dist, page)} is on a hidden track and has no noindex`
        );
      }
    }
  });

  test('a visible track is still indexable', async () => {
    for (const slug of VISIBLE) {
      const page = path.join(dist, 'learn', slug, 'index.html');
      assert.ok(
        !readFileSync(page, 'utf8').includes('content="noindex'),
        `${slug} is visible and should not be noindex`
      );
    }
  });

  test('a hidden track is not in the site search index', async () => {
    for (const slug of HIDDEN) {
      const dir = path.join(dist, 'learn', slug);
      if (!existsSync(dir)) continue;
      for (const page of await walk(dir)) {
        assert.ok(
          !readFileSync(page, 'utf8').includes('data-pagefind-body'),
          `${path.relative(dist, page)} is on a hidden track and is being indexed`
        );
      }
    }
  });

  test('a hidden track still builds, because it is unlisted rather than gone', async () => {
    // Deliberately not a list of expected pages. What a half-written track has
    // varies while it is being written, and the property worth holding is that
    // hiding it removes none of them. Filtering in getLearnTracks instead of on
    // the listing took every generated route out with it, including the
    // coverage page that shows what is left to do, and this is what catches
    // that.
    for (const slug of HIDDEN) {
      const dir = path.join(dist, 'learn', slug);
      assert.ok(existsSync(dir), `${slug} built nothing at all, so hiding it unpublished it`);
      const pages = await walk(dir);
      assert.ok(pages.length > 0, `${slug} built no pages`);
    }
    // The topic route in particular, since it is the one a shared URL points at.
    assert.ok(has('learn/bicep/modules-and-scopes/index.html'));
  });
});
