/**
 * The platform reference page is the Network+ sibling of the distributions
 * page, generated from the topics by the same extractor. Same failure mode: a
 * changed heading or a changed table header collects nothing, the page still
 * builds, and it renders an empty reference nobody notices.
 *
 * These are deliberately loose on counts. The track is being written, so a floor
 * that catches the extractor collecting nothing is useful and a tight number
 * would fail on every topic added.
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
const pagePath = 'learn/network-plus/platforms/index.html';

before(() => {
  assert.ok(
    existsSync(path.join(dist, pagePath)),
    'dist/learn/network-plus/platforms/index.html not found. Run "npm run build" first.'
  );
});

describe('platform differences reference', () => {
  const html = () => readFileSync(path.join(dist, pagePath), 'utf8');

  test('the page collects something', () => {
    const match = /(\d+) differences from (\d+) topics?/.exec(html());
    assert.ok(match, 'the page does not state how many differences it collected');
    assert.ok(Number(match[1]) > 0, 'the extractor collected no rows');
  });

  test('all three host platforms appear as columns', () => {
    const page = html();
    for (const column of ['Linux', 'Windows', 'macOS']) {
      assert.match(page, new RegExp(`>${column}<`), `the ${column} column is missing`);
    }
  });

  test('rows render their backticked commands as code', () => {
    assert.match(html(), /<code>ip addr show<\/code>|<code>ipconfig<\/code>/);
  });

  test('the track index links to it', () => {
    const index = readFileSync(path.join(dist, 'learn/network-plus/index.html'), 'utf8');
    assert.match(index, /learn\/network-plus\/platforms/);
  });

  test('the two tracks do not collect into each other', () => {
    // Each track's heading and column matcher are its own. A regression in the
    // config would most likely show up as one track's page picking up the
    // other's tables, or as a page appearing where none was configured.
    assert.ok(
      !existsSync(path.join(dist, 'learn/network-plus/distributions/index.html')),
      'network-plus should have no distributions page'
    );
    assert.ok(
      !existsSync(path.join(dist, 'learn/linux-plus/platforms/index.html')),
      'linux-plus should have no platforms page'
    );
    assert.doesNotMatch(html(), />RHEL family</, 'a Linux+ table leaked into the platforms page');
  });

  test('the comparison table is tagged on the topic page, not just here', () => {
    // The shared geometry comes from a build integration that tags the table in
    // place. It matched one hardcoded heading for as long as there was one
    // track, so this asserts the Network+ heading is found too.
    const topic = readFileSync(
      path.join(dist, 'learn/network-plus/macs-ips-and-ports/index.html'),
      'utf8'
    );
    assert.match(topic, /<table class="compare"/);
  });
});
