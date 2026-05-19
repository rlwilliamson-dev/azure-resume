/**
 * Format a Date into something like "May 18, 2026".
 * Falls back to ISO date if formatting fails for any reason.
 */
export function formatDate(d: Date): string {
  try {
    return d.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  } catch {
    return d.toISOString().slice(0, 10);
  }
}
