/**
 * Site-wide URL constants.
 *
 * This Astro project builds with `base: '/'` and serves more than one section,
 * so section prefixes live here rather than coming from `import.meta.env.BASE_URL`.
 * Everything that links across sections should import from this file so there is
 * exactly one place to change if a section ever moves.
 */

export const SITE_URL = 'https://rlwilliamson.dev';

/** URL prefix for the Astro blog. Pages live in src/pages/blog. */
export const BLOG_BASE = '/blog';

/** URL prefix for the learn library. Pages live in src/pages/learn. */
export const LEARN_BASE = '/learn';

/**
 * Build an absolute canonical URL from a pathname.
 * Strips trailing slashes so /blog/ and /blog resolve to one canonical form.
 */
export function canonicalFor(pathname: string): string {
  const clean = pathname.replace(/\/+$/, '');
  return `${SITE_URL}${clean === '' ? '/' : clean}`;
}
