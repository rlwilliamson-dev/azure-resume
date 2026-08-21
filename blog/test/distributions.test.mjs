/**
 * The distribution reference page is generated from the topics, which is the
 * only reason it can be trusted. That also makes it silently breakable: change
 * a heading or a table header in the topics and the extractor collects nothing,
 * the page still builds, and it renders an empty reference nobody notices.
 *
 * These assert against the built page for that reason: that it exists, that it
 * carries a substantial number of rows, and that a topic which definitely has a
 * comparison table actually appears in it.
 *
 * Run `npm run build` first, as with the route tests.
 */
import { test, describe, before } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.join(root, 'dist');
const pagePath = 'learn/linux-plus/distributions/index.html';

before(() => {
  assert.ok(
    existsSync(path.join(dist, pagePath)),
    'dist/learn/linux-plus/distributions/index.html not found. Run "npm run build" first.'
  );
});

describe('distribution differences reference', () => {
  const html = () => readFileSync(path.join(dist, pagePath), 'utf8');

  test('the page collects a substantial number of differences', () => {
    const match = /(\d+) differences from (\d+) topics/.exec(html());
    assert.ok(match, 'the page does not state how many differences it collected');
    const [, rows, topics] = match.map(Number);
    // The track had 299 rows across 53 topics when this was written. A floor
    // well under that catches the extractor silently collecting nothing without
    // failing every time a topic is added or reworded.
    assert.ok(rows > 200, `only ${rows} rows collected, expected more than 200`);
    assert.ok(topics > 40, `only ${topics} topics contributed, expected more than 40`);
  });

  test('a topic with a known comparison table appears', () => {
    const page = html();
    // Anchored on the topic's href rather than its title. A title is editorial
    // and gets rewritten; the slug is the URL and changing one is a redirect.
    // This assertion used to name a title and broke the day the titles moved.
    assert.match(page, /\/learn\/linux-plus\/mounting-and-fstab/);
    assert.match(page, /nfs-common/, 'the NFS client package row is missing');
  });

  test('rows render their backticked commands as code', () => {
    assert.match(html(), /<code>dpkg -S PATH<\/code>|<code>update-grub<\/code>/);
  });

  test('three-way comparisons are rendered, not dropped', () => {
    const page = html();
    // Some topics compare RHEL against Debian and Ubuntu separately. Those are
    // real distribution differences and belong here with an extra column.
    assert.match(page, /Ubuntu server|>SUSE</);
  });

  test('the page does not list what it decided against showing', () => {
    assert.doesNotMatch(html(), /Not collected here/);
  });

  test('the track index links to it', () => {
    const index = readFileSync(path.join(dist, 'learn/linux-plus/index.html'), 'utf8');
    assert.match(index, /learn\/linux-plus\/distributions/);
  });

  test('a track with no comparison tables gets no page', () => {
    assert.ok(
      !existsSync(path.join(dist, 'learn/bicep/distributions/index.html')),
      'bicep has no distribution differences and should not have the page'
    );
  });
});
