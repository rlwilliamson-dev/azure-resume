import readingTime from 'reading-time';

/**
 * Compute a human-friendly reading time for a post body.
 * Pass the raw markdown source; the library strips formatting under the hood.
 * Returns a string like "5 min read" — rounded up to the nearest whole minute,
 * minimum 1.
 */
export function calculateReadingTime(body: string): string {
  const stats = readingTime(body);
  const minutes = Math.max(1, Math.ceil(stats.minutes));
  return `${minutes} min read`;
}
