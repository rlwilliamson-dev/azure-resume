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
import { readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.join(root, 'dist');
const pagePath = 'learn/network-plus/platforms/index.html';

/** Every file under dir matching pattern, recursively. */
async function walk(dir, pattern) {
  const found = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) found.push(...(await walk(full, pattern)));
    else if (pattern.test(entry.name)) found.push(full);
  }
  return found;
}

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

/**
 * Across platforms is required, not optional, and the check exists because the
 * rule alone did not hold.
 *
 * The topic template has said since before the first topic was written that a
 * topic gets an "Across platforms" section where the same task has a Linux, a
 * Windows and a macOS answer. Six topics shipped without one anyway, including
 * one whose whole subject was the subnet mask, which every platform writes
 * differently. A rule that is only prose gets skipped on the topics where the
 * author is concentrating on something else, which is all of them.
 *
 * So this triggers on the Linux-only tools the reader is told to run, and makes
 * skipping the section a deliberate act with a reason attached rather than an
 * omission nobody notices.
 */
describe('platform coverage', () => {
  // Tools with a different answer on Windows and macOS. Objective 5.5 names the
  // Windows counterpart of every one of these, so a topic that tells a reader
  // to run the Linux form owes them the other two.
  const TRIGGERS = [
    /\bip\s+(?:-brief\s+)?(?:addr|link|route|neigh)\b/,
    /\bss\s+-[a-z]/,
    /\/etc\/services\b/,
  ];

  // Scaffolding rather than instruction. A capture drives several namespaces
  // from outside them, and those forms are not something a reader ever types.
  const PLUMBING = /\bip\s+(?:-n\s+\S+|netns\s+exec)/;

  // Skipping is allowed. Skipping silently is not, so each one carries why.
  const EXEMPT = {
    '00-start-here':
      'Orientation. No commands, and the tools have not been introduced yet.',
    '03-the-osi-model':
      'Conceptual. Its captures are packet captures driven from outside the namespaces, and a reader is not asked to reproduce them on their own machine.',
    '04-the-boxes-on-a-network':
      'Documented only. Nothing on the page is a command.',
    '06-subnetting-by-hand':
      'Arithmetic, identical on every platform. The page says so in place of a section.',
    '22-dynamic-routing-protocols':
      'The ip route output here is a router showing routes a protocol installed. Topic 21 carries the cross-platform comparison for reading a routing table, and a Windows or macOS host does not run OSPF in any sense this exam asks about.',
    '23-route-selection':
      'Same reason as topic 22. The tables shown are a router choosing between candidate routes, and topic 21 already compares how each platform prints a table.',
    '26-fhrp-vip-and-subinterfaces':
      'The ip commands here build subinterfaces on a router. A Windows or macOS host is not the device doing this, and topic 21 already compares reading a routing table across the three.',
    '28-sdn-sd-wan-and-vxlan':
      'The only ip link on the page builds the VXLAN interface in the lab topology, in the Linux footnote. Encapsulation is done by a hypervisor or a WAN device rather than by a desktop, so there is no Windows or macOS equivalent a reader would run, and inventing one would be worse than the omission.',
    '56-layer-2-attacks':
      'The ip neigh and bridge commands are in the Linux footnote and describe the lab\'s own attacker and inspection tooling: raw sockets and a Linux bridge, which are Linux-specific. Reading a neighbour or ARP cache across the three platforms belongs to the connection-and-interface-tools troubleshooting topic, and inventing a Windows attack transcript would be worse than the omission.',
    '58-device-hardening-and-network-access-control':
      'The ip link set address is the lab attacker changing its MAC, in the port-security demo and the Linux footnote. 802.1X and MAC filtering are configured on the switch, not on a Windows or macOS host, so there is no desktop command a reader runs that would have a cross-platform answer.',
    '59-cloud-concepts-and-connectivity':
      'The ip route is a Linux-footnote analogy for a virtual private cloud being subnets and routing. The cloud constructs have no per-desktop command on any platform, and reading a routing table across the three is already owned by the routing-table topic.',
  };

  test('every topic telling a reader to run a Linux-only tool compares platforms', async () => {
    const dir = path.join(root, 'src/content/learn/network-plus');
    if (!existsSync(dir)) return;

    const offenders = [];
    for (const file of await walk(dir, /\.md$/)) {
      const slug = path.basename(file, '.md');
      const text = readFileSync(file, 'utf8');
      if (/^## Across platforms$/m.test(text)) continue;

      // Only lines a reader would type: prose, and command lists. A transcript
      // line already carries its own prompt and belongs to a capture.
      const candidates = text
        .split('\n')
        .filter((line) => !/^\s*[$>]\s/.test(line))
        .filter((line) => !PLUMBING.test(line));

      const hit = candidates.find((line) => TRIGGERS.some((re) => re.test(line)));
      if (!hit) continue;
      if (EXEMPT[slug]) continue;

      offenders.push(`${slug}: ${hit.trim().slice(0, 70)}`);
    }

    assert.deepEqual(
      offenders,
      [],
      'These topics tell a reader to run a Linux-only tool and never say what ' +
        'the Windows or macOS answer is. Add an "## Across platforms" section, ' +
        'or add the topic to EXEMPT in this test with the reason:\n  ' +
        offenders.join('\n  ')
    );
  });
});

/**
 * Internal learn links have to resolve.
 *
 * check-links.mjs verifies the citations, which point outward. Nothing verified
 * the links pointing at this site's own pages, and the cross-track see-also
 * links shipped broken because a topic's file is named 16-network-basics and
 * its URL is /learn/linux-plus/network-basics: the loader strips the ordering
 * prefix and a link written from the filename lands nowhere.
 *
 * A wrong internal link is worse than a wrong citation, because a reader who
 * followed it has already been told the page exists.
 */
describe('internal learn links', () => {
  test('every /learn/ link in a topic points at a page that was built', async () => {
    const dir = path.join(root, 'src/content/learn');
    if (!existsSync(dir)) return;

    const broken = [];
    for (const file of await walk(dir, /\.md$/)) {
      const text = readFileSync(file, 'utf8');
      for (const [, href] of text.matchAll(/\]\((\/learn\/[^)#\s]*)/g)) {
        const clean = href.replace(/\/$/, '');
        const built =
          existsSync(path.join(dist, clean, 'index.html')) ||
          existsSync(path.join(dist, `${clean}.html`));
        if (!built) broken.push(`${path.basename(file)} -> ${href}`);
      }
    }

    assert.deepEqual(
      broken,
      [],
      'These links point at pages that do not exist in dist. A topic URL drops ' +
        'the numeric prefix from its filename, so /learn/<track>/<slug> uses ' +
        'the slug without it:\n  ' + broken.join('\n  ')
    );
  });
});

/**
 * Link text has to match the page it points at.
 *
 * The internal link test above proves a link resolves. It does not prove the
 * link says the right thing, and those are different failures. Renaming the
 * topics left six cross-track links reading "Addresses, masks, and who counts
 * as a neighbour" while the page they opened was called something else, so
 * every one of them resolved perfectly and lied about the destination.
 *
 * A reader cannot tell the difference between a link that goes somewhere else
 * and a link whose name is out of date, which is why this is worth failing on.
 */
describe('internal link text', () => {
  test('a link naming a topic uses that topic\'s current title', async () => {
    const dir = path.join(root, 'src/content/learn');
    if (!existsSync(dir)) return;

    // slug -> title, for every topic in every track
    const titles = new Map();
    for (const file of await walk(dir, /\.md$/)) {
      const track = path.basename(path.dirname(file));
      const slug = path.basename(file, '.md').replace(/^\d+-/, '');
      const title = readFileSync(file, 'utf8').match(/^title:\s*"(.*)"$/m);
      if (title) titles.set(`${track}/${slug}`, title[1]);
    }

    const stale = [];
    for (const file of await walk(dir, /\.md$/)) {
      const text = readFileSync(file, 'utf8');
      const link = /\[([^\]]{3,120})\]\(\/learn\/([a-z0-9-]+)\/([a-z0-9-]+)\)/g;
      for (const [, raw, track, slug] of text.matchAll(link)) {
        const current = titles.get(`${track}/${slug}`);
        // Route pages such as /plan and /coverage are not topics.
        if (!current) continue;
        const label = raw.replace(/\s+/g, ' ').trim();
        // Prose legitimately wraps a title in a longer phrase; the test only
        // objects when the label looks like a title and is the wrong one.
        if (label.toLowerCase().includes(current.toLowerCase())) continue;
        stale.push(`${path.basename(file)}\n      says: ${label}\n      is:   ${current}`);
      }
    }

    assert.deepEqual(
      stale,
      [],
      'These links name a topic by a title it no longer has:\n  ' + stale.join('\n  ')
    );
  });
});

/**
 * A topic that captured something owes the reader a chance to guess first.
 *
 * `details.predict` hides one captured block behind a question, so a reader
 * commits to an answer before scrolling past it. The topic template requires it
 * and there was no test, which is how it went missing: the convention held for
 * the first thirty-four topics and then stopped, leaving twenty-nine topics with
 * real captured output and no prediction anywhere on the page. Nothing failed,
 * nothing rendered wrong, and the feature quietly stopped being used.
 *
 * Same shape as the platform coverage check above, and for the same reason. A
 * rule nobody enforces is a preference.
 */
describe('predict panels', () => {
  // A provenance header is what makes a fenced block a capture rather than a
  // list of commands for the reader to run.
  const CAPTURE = /^# (?:.+, kernel |Microsoft Windows |macOS |Fedora |Debian |Ubuntu )/m;

  // Skipping is allowed and has to carry a reason.
  const EXEMPT = {};

  test('every topic with captured output hides one block behind a question', async () => {
    const dir = path.join(root, 'src/content/learn/network-plus');
    if (!existsSync(dir)) return;

    const offenders = [];
    for (const file of await walk(dir, /\.md$/)) {
      const slug = path.basename(file, '.md');
      if (EXEMPT[slug]) continue;
      const text = readFileSync(file, 'utf8');
      if (!CAPTURE.test(text)) continue;
      if (text.includes('<details class="predict">')) continue;
      offenders.push(slug);
    }

    assert.deepEqual(
      offenders,
      [],
      'These topics carry captured output and never ask the reader to predict ' +
        'any of it. Wrap one capture in a "details.predict" panel with a question ' +
        'in its summary, or add the topic to EXEMPT in this test with the reason:\n  ' +
        offenders.join('\n  ')
    );
  });

  test('a predict panel asks a question and contains the capture', async () => {
    const dir = path.join(root, 'src/content/learn/network-plus');
    if (!existsSync(dir)) return;

    const offenders = [];
    for (const file of await walk(dir, /\.md$/)) {
      const text = readFileSync(file, 'utf8');
      const panels = text.matchAll(
        /<details class="predict">\n<summary>(.*?)<\/summary>\n([\s\S]*?)<\/details>/g
      );
      for (const [, summary, body] of panels) {
        const where = `${path.basename(file, '.md')}: "${summary.slice(0, 60)}"`;
        if (!summary.includes('?')) offenders.push(`${where} has no question in its summary`);
        if (!/```/.test(body)) offenders.push(`${where} holds no fenced block`);
      }
    }

    assert.deepEqual(offenders, [], `malformed predict panels:\n  ${offenders.join('\n  ')}`);
  });
});
