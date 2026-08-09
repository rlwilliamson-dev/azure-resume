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
    name: 'Security+',
    description:
      'CompTIA Security+ study notes organized by exam domain, with practice questions.',
    position: 30,
  },
  'linux-plus': {
    name: 'CompTIA Linux+',
    description:
      'XK0-006 study notes written objective by objective, with cited sources, cross-distribution differences, and practice questions that link back to the material.',
    position: 40,
  },
};

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
