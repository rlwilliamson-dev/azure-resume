/**
 * Display metadata for learn tracks.
 *
 * A track is a directory under src/content/learn. That directory is the only
 * thing that creates a track. This file is optional polish: it overrides the
 * display name, description, and sort position for a track that already exists
 * on disk. A directory with no entry here still builds, using a humanized
 * version of its slug and sorting after every track that has a position.
 *
 * Nothing else in the codebase should name a track.
 */

export interface TrackMeta {
  /** Display name shown in headings and navigation. */
  name: string;
  /** One-line description shown on the learn landing page. */
  description: string;
  /** Lower sorts first. Leave gaps so you can insert without renumbering. */
  position: number;
}

export const TRACK_META: Record<string, TrackMeta> = {
  bicep: {
    name: 'Bicep',
    description:
      'Azure infrastructure as code: modules, scopes, deployment behavior, and the parts the docs gloss over.',
    position: 10,
  },
  databricks: {
    name: 'Databricks',
    description:
      'Workspace architecture, compute, and data engineering patterns on the Databricks platform.',
    position: 20,
  },
  'security-plus': {
    // A CompTIA certification name must not appear without the word "CompTIA",
    // per their trademark guidance. Same rule that names the Linux+ track.
    name: 'CompTIA Security+',
    description:
      'CompTIA Security+ study notes organized by exam domain, with practice questions.',
    position: 30,
  },
  'network-plus': {
    name: 'CompTIA Network+',
    description:
      'N10-009 study notes written objective by objective, with cited sources, protocol behaviour captured from running networks rather than drawn, and practice questions that link back to the material.',
    position: 35,
  },
  'linux-plus': {
    name: 'CompTIA Linux+',
    description:
      'XK0-006 study notes written objective by objective, with cited sources, cross-distribution differences, and practice questions that link back to the material.',
    position: 40,
  },
};

/**
 * Comparison tables, and the generated reference page that collects them.
 *
 * Several topics in a certification track answer the same question in more than
 * one place: on RHEL against Debian, or on a switch against Linux against
 * Windows. Those tables are the densest revision material a vendor-neutral exam
 * has, and inside the topics they are the most scattered, one table at a time
 * across seventy-odd lessons.
 *
 * A track declares the heading its topics use and the page that collects them.
 * Everything else derives: lib/comparisons.ts extracts the tables, the
 * compare-tables integration tags them for shared geometry, and the route builds
 * the page. A track with no entry here has no comparison page, which is what
 * keeps this off Bicep without a list of exclusions.
 *
 * One convention the integration depends on: the heading begins with "Across".
 * That is what lets a build step written in plain JavaScript find these sections
 * without importing this file.
 */
export interface CompareMeta {
  /** The h2 a topic puts its comparison table under. Must begin with "Across". */
  heading: string;
  /** URL segment for the generated page, under /learn/<track>/. */
  slug: string;
  /** Heading shown on that page. */
  title: string;
  /** The terminal-style command rendered as the page heading. */
  command: string;
  description: string;
  lede: string;
  /**
   * Column headings that name something being compared rather than the row
   * label. A table qualifies when at least one column matches, which lets
   * through three-way splits without hardcoding how many columns there are.
   */
  columnPattern: RegExp;
  /** Headings that sit on the row-label column and are not being compared. */
  labelHeadings: string[];
}

export const COMPARE_META: Record<string, CompareMeta> = {
  'linux-plus': {
    heading: 'Across distributions',
    slug: 'distributions',
    title: 'distribution differences',
    command: 'diff rhel debian',
    description:
      'Every RHEL and Debian family difference in the track, collected from the topics into one reference.',
    lede:
      'This is the material a vendor-neutral exam exists to test, and it is the part you cannot reason your way to: the same software under a different package name, a different service name, and a different path.',
    columnPattern:
      /^(RHEL|Debian|RPM|dpkg|Ubuntu|SUSE|openSUSE|SLES|AlmaLinux|Rocky|Fedora|CentOS)\b/i,
    labelHeadings: ['To check that'],
  },
  'network-plus': {
    heading: 'Across platforms',
    slug: 'platforms',
    title: 'platform differences',
    command: 'diff linux windows macos',
    description:
      'The same networking task on Linux, Windows, macOS and a vendor CLI, collected from the topics into one reference.',
    lede:
      'The exam is vendor-neutral and names three host tools for the same job, so it will ask for the result rather than the command you happen to know. These are the places where the answer has a different name depending on where you type it.',
    columnPattern: /^(Linux|Windows|macOS|Vendor CLI|Cisco|IOS)\b/i,
    labelHeadings: ['Task', 'To check that'],
  },
};

/** Comparison metadata for a track, or null if it has no comparison page. */
export function compareMetaFor(slug: string): CompareMeta | null {
  return COMPARE_META[slug] ?? null;
}

/** Fallback sort position for a track directory with no TRACK_META entry. */
export const UNRANKED_POSITION = 1000;

/**
 * Turn a directory slug into a readable name: "security-plus" -> "Security Plus".
 * Only used when a track has no TRACK_META entry.
 */
export function humanizeSlug(slug: string): string {
  return slug
    .split('-')
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

/** Resolve display metadata for a track slug, falling back to derived values. */
export function trackMetaFor(slug: string): TrackMeta {
  return (
    TRACK_META[slug] ?? {
      name: humanizeSlug(slug),
      description: '',
      position: UNRANKED_POSITION,
    }
  );
}
