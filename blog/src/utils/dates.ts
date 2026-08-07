/**
 * Format a Date into something like "May 18, 2026".
 * Falls back to ISO date if formatting fails for any reason.
 *
 * Formatted in UTC on purpose. Date-only frontmatter such as `2026-05-18` is
 * parsed as UTC midnight, so formatting in the build machine's local zone
 * renders the previous day anywhere behind UTC. CI happens to run in UTC, but
 * relying on that makes local previews disagree with production.
 */
export function formatDate(d: Date): string {
  try {
    return d.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      timeZone: 'UTC',
    });
  } catch {
    return d.toISOString().slice(0, 10);
  }
}
