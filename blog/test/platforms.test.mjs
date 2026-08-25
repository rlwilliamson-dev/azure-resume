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
  //
  // The ip form allows a short option between the command and the object.
  // `ip -s link show` is the same instruction as `ip link show` as far as a
  // Windows or macOS reader is concerned, and the earlier regex, anchored on
  // ip immediately followed by the object, let it through. Topic 18 was the
  // topic it let through: its Try it told a reader to run ethtool and
  // `ip -s link show` and offered Windows "open the adapter properties".
  const TRIGGERS = [
    /\bip\s+(?:-\S+\s+)*(?:addr|link|route|neigh)\b/,
    /\bss\s+-[a-z]/,
    /\bethtool\s+\S/,
    /\/etc\/services\b/,
  ];

  // The Security+ track runs a different set of Linux-only tools, so it gets
  // its own trigger list rather than sharing this one. Reading a certificate,
  // a security log, an account file or a disk encryption state is the same
  // question on every platform and a different command on each, which is the
  // property that makes a tool worth triggering on.
  const SECURITY_TRIGGERS = [
    /\bopenssl\s+\S/,
    /\b(?:sha256sum|sha512sum|md5sum)\b/,
    /\bgpg\s+-/,
    /\bssh-keygen\b/,
    /\bjournalctl\b/,
    /\b(?:ausearch|auditctl)\b/,
    /\b(?:getenforce|sestatus)\b/,
    /\bss\s+-[a-z]/,
    /\b(?:iptables|nft)\s+\S/,
    /\bfirewall-cmd\s+--/,
    /\bdig\s+\S/,
    /\b(?:passwd|chage)\s+-\w/,
    /\blastb\b|\blast\s+-\w/,
    /\bstat\s+[-/]/,
    /\bcryptsetup\s+\S/,
    /\b(?:update-ca-trust|trust\s+list)\b|\/etc\/ssl\/certs\b/,
  ];

  // Scaffolding rather than instruction. A capture drives several namespaces
  // from outside them, and those forms are not something a reader ever types.
  const PLUMBING = /\bip\s+(?:-n\s+\S+|netns\s+exec)/;

  // The Security+ equivalent: a line invoking the capture toolchain is showing
  // how a block was produced, not telling a reader to run it.
  const SECURITY_PLUMBING = /\b(?:capture|hostcap|netlab)\.sh\b/;

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
    '18-interface-configuration-and-link-aggregation':
      'Its Try it names the Linux, Windows and macOS command on every line, and the interface-counters topic owns the four-column table for reading a port across the three. A second table here would repeat it.',
    '69-switching-faults-loops-and-vlans':
      'The ip -d link show reads spanning tree state off the Linux bridge acting as the lab\'s switch. A Windows or macOS host is not the device holding that state, and topic 19 covers reading it from a switch.',
    '75-bandwidth-congestion-and-bottlenecks':
      'The method block names one Linux-only command and the paragraph under it gives the Windows and macOS counter for the same job. The interface-counters topic owns the four-column table and captures all three.',
    '59-cloud-concepts-and-connectivity':
      'The ip route is a Linux-footnote analogy for a virtual private cloud being subnets and routing. The cloud constructs have no per-desktop command on any platform, and reading a routing table across the three is already owned by the routing-table topic.',
  };

  // Same shape as EXEMPT above, keyed by Security+ slug.
  const SECURITY_EXEMPT = {
    '00-start-here':
      'Orientation. No commands, and the tools have not been introduced yet.',
  };

  const TRACKS = [
    { track: 'network-plus', triggers: TRIGGERS, plumbing: PLUMBING, exempt: EXEMPT },
    {
      track: 'security-plus',
      triggers: SECURITY_TRIGGERS,
      plumbing: SECURITY_PLUMBING,
      exempt: SECURITY_EXEMPT,
    },
  ];

  for (const { track, triggers, plumbing, exempt } of TRACKS) {
    test(`${track}: every topic telling a reader to run a Linux-only tool compares platforms`, async () => {
      const dir = path.join(root, 'src/content/learn', track);
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
          .filter((line) => !plumbing.test(line));

        const hit = candidates.find((line) => triggers.some((re) => re.test(line)));
        if (!hit) continue;
        if (exempt[slug]) continue;

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

    test(`${track}: every exempted slug still names a topic`, async () => {
      const dir = path.join(root, 'src/content/learn', track);
      if (!existsSync(dir)) return;
      const slugs = new Set((await walk(dir, /\.md$/)).map((f) => path.basename(f, '.md')));
      const dead = Object.keys(exempt).filter((slug) => !slugs.has(slug));
      assert.deepEqual(dead, [], `EXEMPT names topics that do not exist: ${dead.join(', ')}`);
    });
  }
});

/**
 * A comparison table that nothing backs up is a claim, not a capture.
 *
 * The section above proves a topic has an Across platforms section. It does not
 * prove the section is worth anything, and three topics shipped a full
 * four-column Task/Linux/Windows/macOS table without one line of Windows or
 * macOS output under it. A reader has no way to tell the difference between a
 * row somebody ran and a row somebody remembered, and the whole point of the
 * capture toolchain is that they should never have to.
 *
 * So a topic that puts macOS in a comparison table owes a capture from each of
 * the other two platforms, or an entry here saying why it cannot have one.
 * Wireless is the honest reason: a GitHub Actions runner has no radio.
 */
describe('platform captures', () => {
  const HOST_TABLE = /^\|\s*(?:Task|The question)\s*\|\s*(?:The\s+)?Linux\s*\|\s*Windows\s*\|\s*macOS\s*\|/m;
  const WINDOWS_CAPTURE = /^# Microsoft Windows /m;
  const MACOS_CAPTURE = /^# macOS /m;

  const EXEMPT = {
    '01-what-a-network-actually-is':
      'Its table is a preview of the four questions, and the section says in as many words that the next topic captures all three platforms answering them side by side. Topic 02 does.',
    '29-wireless-and-cellular-media':
      'A GitHub Actions runner has no wireless adapter, so iw, netsh wlan show interfaces and wdutil have nothing to report on either machine. Capturing this needs hardware the toolchain does not have.',
    '72-wireless-performance-and-roaming':
      'Same reason as topic 29. Every row of its table asks a radio a question and neither runner has one.',
  };

  // Same shape, keyed by Security+ slug. Empty until a topic earns an entry.
  const SECURITY_EXEMPT = {};

  const TRACKS = [
    { track: 'network-plus', exempt: EXEMPT },
    { track: 'security-plus', exempt: SECURITY_EXEMPT },
  ];

  for (const { track, exempt } of TRACKS) {
    test(`${track}: a four-column host table carries a Windows and a macOS capture`, async () => {
      const dir = path.join(root, 'src/content/learn', track);
      if (!existsSync(dir)) return;

      const offenders = [];
      for (const file of await walk(dir, /\.md$/)) {
        const slug = path.basename(file, '.md');
        const text = readFileSync(file, 'utf8');
        if (!HOST_TABLE.test(text)) continue;
        if (exempt[slug]) continue;

        const missing = [];
        if (!WINDOWS_CAPTURE.test(text)) missing.push('Windows');
        if (!MACOS_CAPTURE.test(text)) missing.push('macOS');
        if (missing.length) offenders.push(`${slug}: no ${missing.join(' or ')} capture`);
      }

      assert.deepEqual(
        offenders,
        [],
        'These topics compare three platforms in a table and prove none of it. ' +
          'Write a capture script under blog/scripts/windows/ and blog/scripts/macos/ ' +
          'and run it through hostcap.sh, or add the topic to EXEMPT in this test ' +
          'with the reason:\n  ' + offenders.join('\n  ')
      );
    });

    test(`${track}: every exempted slug still names a topic`, async () => {
      // An exemption keyed by a slug that no longer exists is a reason nobody can
      // check against a page nobody can read. Renaming a topic should break this
      // rather than quietly leaving the entry behind.
      const dir = path.join(root, 'src/content/learn', track);
      if (!existsSync(dir)) return;

      const slugs = new Set((await walk(dir, /\.md$/)).map((f) => path.basename(f, '.md')));
      const dead = Object.keys(exempt).filter((slug) => !slugs.has(slug));

      assert.deepEqual(dead, [], `EXEMPT names topics that do not exist: ${dead.join(', ')}`);
    });
  }
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
  //
  // This used to name the distributions one at a time, and the list was missing
  // AlmaLinux and openSUSE, which are two of the four images capture.sh pins.
  // Twelve topics across both existing tracks were therefore invisible to the
  // floor below, and it would have exempted most of the Security+ cryptography
  // block, which is captured almost entirely on AlmaLinux. Matching the shape
  // of the header rather than a list of names closes it: every capture.sh block
  // ends its header with an architecture, every netlab block names a kernel,
  // and Windows names itself. All twelve already met the floor, which is what a
  // rule people are following looks like when the test catches up with it.
  const CAPTURE = /^# (?:.+, kernel |Microsoft Windows )|^# .+, (?:x86_64|aarch64|arm64|amd64)\b/m;

  // The floor is two, which is the lowest any Linux+ topic with captures goes.
  // These nine already wrap every capture they have, so a second panel would
  // need a new capture rather than a new question.
  const ONE_PANEL_ONLY = new Set([
    '15-unicast-multicast-anycast-broadcast',
    '17-trunking-and-802-1q-tagging',
    '18-interface-configuration-and-link-aggregation',
    '19-spanning-tree',
    '20-mtu-and-jumbo-frames',
    '23-route-selection',
    '25-nat-and-pat',
    '26-fhrp-vip-and-subinterfaces',
    '65-narrowing-a-fault-by-layer',
    '06-subnetting-by-hand',
    '24-vlsm-and-planning-an-address-space',
    '34-encryption-certificates-and-pki',
  ]);

  // Skipping entirely is allowed and has to carry a reason.
  const EXEMPT = {};

  test('every topic with captured output hides one block behind a question', async () => {
    // Both certification tracks, because both were written to this rule and only
    // one of them was ever checked against it. Widening the walk turned up
    // exactly one topic below the floor, which is what a rule people already
    // follow looks like when the test finally catches up with it.
    const dirs = ['network-plus', 'linux-plus', 'security-plus']
      .map((t) => path.join(root, 'src/content/learn', t))
      .filter((d) => existsSync(d));
    if (dirs.length === 0) return;

    const files = (await Promise.all(dirs.map((d) => walk(d, /\.md$/)))).flat();

    const offenders = [];
    for (const file of files) {
      const slug = path.basename(file, '.md');
      if (EXEMPT[slug]) continue;
      const text = readFileSync(file, 'utf8');
      if (!CAPTURE.test(text)) continue;
      const panels = (text.match(/<details class="predict">/g) ?? []).length;
      const floor = ONE_PANEL_ONLY.has(slug) ? 1 : 2;
      if (panels < floor) offenders.push(`${slug}: ${panels}, needs ${floor}`);
    }

    assert.deepEqual(
      offenders,
      [],
      'These topics carry captured output and ask the reader to predict less of ' +
        'it than the floor. Wrap another capture in a "details.predict" panel ' +
        'with a question in its summary, or add the topic to ONE_PANEL_ONLY or ' +
        'EXEMPT in this test with the reason:\n  ' +
        offenders.join('\n  ')
    );
  });

  test('a predict panel asks a question and contains the capture', async () => {
    const dirs = ['network-plus', 'security-plus']
      .map((t) => path.join(root, 'src/content/learn', t))
      .filter((d) => existsSync(d));
    if (dirs.length === 0) return;
    const files = (await Promise.all(dirs.map((d) => walk(d, /\.md$/)))).flat();

    const offenders = [];
    for (const file of files) {
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

/**
 * A topic owes its expert readers more than one panel.
 *
 * The plan asks for a `details.deeper` panel per major body section. Neither
 * track reaches that, and Linux+ never drops below three panels on a topic,
 * which is the floor this enforces. Network+ decayed from four or five a topic
 * down to two by topic 17 and one by topic 28, with two topics carrying none at
 * all, and nothing failed while it happened. Same shape as the predict panels
 * above and the same remedy.
 *
 * The floor is `min(3, body sections)`, so a short topic is not asked for panels
 * it has nowhere to put. Scaffolding sections are excluded: a panel belongs to a
 * section that teaches something.
 */
describe('deeper panels', () => {
  const SCAFFOLD = new Set([
    'some words you will need', 'what breaks without this', 'across platforms',
    'prove it', 'prove it again', 'what trips people up', 'work it through',
    'try it', 'check yourself', 'references', 'for the exam', 'where this sits',
  ]);

  // Skipping is allowed and has to carry a reason. Keyed by slug, which both
  // tracks number from 00, so an entry names a topic on either.
  const EXEMPT = {
    '00-start-here': 'Orientation. It has no body sections to hang a panel on.',
  };

  // Linux+ is deliberately absent. It predates the panel-per-section rule and
  // never drops below three, so adding it here would assert something already
  // true without the rule having been written for it.
  const DIRS = ['network-plus', 'security-plus'];

  test('every topic carries a panel on at least three body sections', async () => {
    const dirs = DIRS.map((t) => path.join(root, 'src/content/learn', t)).filter((d) =>
      existsSync(d)
    );
    if (dirs.length === 0) return;
    const files = (await Promise.all(dirs.map((d) => walk(d, /\.md$/)))).flat();

    const offenders = [];
    for (const file of files) {
      const slug = path.basename(file, '.md');
      if (EXEMPT[slug]) continue;
      const text = readFileSync(file, 'utf8');
      const body = text.split('---').slice(2).join('---');

      // A panel belongs to the heading above it, so split on headings and ask
      // which of the resulting sections contains one.
      const parts = body.split(/^## /m).slice(1);
      let sections = 0;
      let covered = 0;
      for (const part of parts) {
        const heading = part.split('\n')[0].trim().toLowerCase().replace(/\.$/, '');
        if (SCAFFOLD.has(heading)) continue;
        sections += 1;
        if (part.includes('<details class="deeper">')) covered += 1;
      }

      const floor = Math.min(3, sections);
      if (covered < floor) {
        offenders.push(`${slug}: ${covered} of ${sections} body sections, needs ${floor}`);
      }
    }

    assert.deepEqual(
      offenders,
      [],
      'These topics carry fewer deeper panels than the floor of three body ' +
        'sections. Add a panel to a section that has none, or add the topic to ' +
        'EXEMPT in this test with the reason:\n  ' +
        offenders.join('\n  ')
    );
  });

  test('a deeper panel has a summary that says who it is for', async () => {
    const dirs = DIRS.map((t) => path.join(root, 'src/content/learn', t)).filter((d) =>
      existsSync(d)
    );
    if (dirs.length === 0) return;
    const files = (await Promise.all(dirs.map((d) => walk(d, /\.md$/)))).flat();

    const offenders = [];
    for (const file of files) {
      const text = readFileSync(file, 'utf8');
      for (const [, summary] of text.matchAll(
        /<details class="deeper">\n<summary>(.*?)<\/summary>/g
      )) {
        if (summary.trim().length < 20) {
          offenders.push(`${path.basename(file, '.md')}: "${summary}"`);
        }
      }
    }

    assert.deepEqual(offenders, [], `thin deeper summaries:\n  ${offenders.join('\n  ')}`);
  });
});

/**
 * Every lesson carries at least one figure.
 *
 * This is the one rule on the Security+ track that was asked for explicitly and
 * that neither existing track ever had a test for. It turns out both of them
 * already obey it: Network+ ships 115 figures across 82 of its 83 topics and
 * Linux+ ships 82 across 80 of 81, and in both cases the topic without one is
 * the orientation page. So this is not a new standard, it is the standard both
 * tracks already hold, finally written down somewhere that fails a build.
 *
 * It matters most on a track that is three quarters conceptual by exam weight,
 * because a page with no picture on it is exactly where an abstraction gets
 * asserted rather than drawn.
 *
 * Skipping is allowed and carries a reason, and the exempt list is itself
 * checked, for the same reason the other exempt lists here are: an entry keyed
 * to a slug that no longer exists is a reason nobody can check.
 */
describe('figure floor', () => {
  // Matches the class prefix rather than the exact attribute, because a
  // photograph figure carries "learn-figure photo" and a topic illustrated only
  // with photographs would otherwise read as having none.
  const FIGURE = /<figure class="learn-figure[ "]/;

  const EXEMPT = {
    'security-plus/00-start-here':
      'Orientation. It explains how to read the track and carries no concept to draw.',
  };

  const DIRS = ['security-plus'];

  test('every lesson carries at least one figure', async () => {
    const dirs = DIRS.map((t) => path.join(root, 'src/content/learn', t)).filter((d) =>
      existsSync(d)
    );
    if (dirs.length === 0) return;

    const offenders = [];
    for (const dir of dirs) {
      const track = path.basename(dir);
      for (const file of await walk(dir, /\.md$/)) {
        const key = `${track}/${path.basename(file, '.md')}`;
        if (EXEMPT[key]) continue;
        if (!FIGURE.test(readFileSync(file, 'utf8'))) offenders.push(key);
      }
    }

    assert.deepEqual(
      offenders,
      [],
      'These topics carry no figure. Draw the argument the topic makes, not the ' +
        'arrangement it describes, or add the topic to EXEMPT in this test with ' +
        'the reason:\n  ' + offenders.join('\n  ')
    );
  });

  test('every exempted slug still names a topic', async () => {
    const present = new Set();
    for (const track of DIRS) {
      const dir = path.join(root, 'src/content/learn', track);
      if (!existsSync(dir)) continue;
      for (const file of await walk(dir, /\.md$/)) {
        present.add(`${track}/${path.basename(file, '.md')}`);
      }
    }
    if (present.size === 0) return;

    const dead = Object.keys(EXEMPT).filter((key) => !present.has(key));
    assert.deepEqual(dead, [], `EXEMPT names topics that do not exist: ${dead.join(', ')}`);
  });
});
