/**
 * Nothing in a diagram should be hidden behind anything else.
 *
 * Reviewing this by eye does not work. A figure is a hundred lines of
 * coordinates, the collisions are a few pixels, and they appear when a label
 * grows by one word rather than when it is written. So the geometry is checked
 * arithmetically instead, against the four ways a label gets lost: it runs off
 * the edge, it lands on another label, a stroke thick enough to swallow it
 * passes underneath, or a shape drawn later paints over it.
 *
 * The text box comes from three constants measured in a browser against the
 * figures themselves, which is what makes this accurate without one. A hairline
 * gridline crossing a label is deliberately allowed: that is a chart
 * convention, not a defect.
 */
import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { findCollisions } from './figure-collisions.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const learn = path.join(root, 'src/content/learn');

async function tracks() {
  const entries = await readdir(learn, { withFileTypes: true });
  return entries.filter((e) => e.isDirectory()).map((e) => e.name);
}

describe('diagram legibility', () => {
  test('no label is overlapped, buried or off the edge', async () => {
    const offenders = [];
    for (const track of await tracks()) {
      const dir = path.join(learn, track);
      for (const file of (await readdir(dir)).filter((n) => n.endsWith('.md'))) {
        const source = readFileSync(path.join(dir, file), 'utf8');
        offenders.push(...findCollisions(source, `${track}/${file.replace('.md', '')}`));
      }
    }
    assert.deepEqual(offenders, [], `text is not legible in:\n${offenders.join('\n')}`);
  });

  test('the checker catches each way a label gets lost', () => {
    // A geometry check that silently passes everything is worse than none, so
    // the four failure modes are asserted against known-bad figures here.
    const cases = {
      overlapping: '<svg viewBox="0 0 200 60"><text x="10" y="30" font-size="12">hello there</text><text x="40" y="32" font-size="12">world</text></svg>',
      struck: '<svg viewBox="0 0 200 60"><line x1="0" y1="26" x2="200" y2="26" stroke-width="2"/><text x="40" y="30" font-size="12">crossed</text></svg>',
      buried: '<svg viewBox="0 0 200 60"><text x="20" y="30" font-size="12">buried</text><rect x="10" y="14" width="120" height="30" fill="currentColor" fill-opacity="0.8"/></svg>',
      offEdge: '<svg viewBox="0 0 200 60"><text x="150" y="30" font-size="12">this runs past the right edge</text></svg>',
    };
    for (const [name, svg] of Object.entries(cases)) {
      assert.ok(findCollisions(svg, name).length > 0, `${name} should have been caught`);
    }

    const fine = '<svg viewBox="0 0 200 60"><text x="10" y="20" font-size="10">one</text><text x="10" y="40" font-size="10">two</text></svg>';
    assert.deepEqual(findCollisions(fine, 'fine'), [], 'a clean figure should pass');

    // A hairline gridline crossing a label is a chart convention, not a fault.
    const gridline = '<svg viewBox="0 0 200 60"><line x1="60" y1="0" x2="60" y2="60" stroke-width="1"/><text x="20" y="30" font-size="10">label</text></svg>';
    assert.deepEqual(findCollisions(gridline, 'gridline'), [], 'a hairline should be allowed');
  });
});
