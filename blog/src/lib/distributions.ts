/**
 * Pulls the "Across distributions" comparison tables out of topic bodies.
 *
 * The RHEL and Debian split is the highest-yield revision material on a
 * vendor-neutral exam, and it is also the most scattered: several hundred rows
 * spread one table at a time across the track. Reading them together is a
 * different job from reading any one topic, so the reference page collects them.
 *
 * Extracted from the markdown rather than maintained by hand, because a
 * hand-written cheat sheet drifts from the topics the moment either one is
 * edited, and the drift is invisible.
 *
 * Not every "Across distributions" section is a two-family comparison. Some
 * compare three distributions, some compare shells, one is prose with no table
 * at all. Those are skipped rather than forced into a shape they do not fit, and
 * skipped sections are reported so the omission is visible instead of silent.
 */

export interface DistroRow {
  /** The left-hand cell: what is being compared. */
  label: string;
  /** One cell per family column, in the order the source table lists them. */
  cells: string[];
}

export interface DistroTable {
  topicTitle: string;
  topicHref: string;
  topicOrder: number;
  /** Column headings, minus the empty leading cell. */
  columns: string[];
  rows: DistroRow[];
}

export interface DistroSkip {
  topicTitle: string;
  topicHref: string;
  reason: string;
}

export interface DistroReport {
  tables: DistroTable[];
  skipped: DistroSkip[];
  rowCount: number;
}

/** Section heading the tables live under. */
const SECTION = /^## Across distributions\s*$/m;

/** A markdown table row: leading and trailing pipes, cells between. */
const ROW = /^\|(.*)\|\s*$/;

/** The separator row markdown uses under a header, such as | --- | --- |. */
const SEPARATOR = /^[\s|:-]+$/;

/**
 * Column headings that mean "this is a two-family comparison". Anything else,
 * such as a three-way split or a shell comparison, is left in its own topic
 * where the surrounding prose explains it.
 */
const FAMILY_COLUMNS = ['RHEL family', 'Debian family', 'RPM family', 'dpkg family'];

function splitCells(line: string): string[] {
  const match = ROW.exec(line);
  if (!match) return [];
  return match[1].split('|').map((cell) => cell.trim());
}

/** The body text between "## Across distributions" and the next h2. */
function sectionBody(body: string): string | null {
  const start = SECTION.exec(body);
  if (!start) return null;
  const after = body.slice(start.index + start[0].length);
  const next = /^## /m.exec(after);
  return next ? after.slice(0, next.index) : after;
}

export interface TopicInput {
  title: string;
  href: string;
  order: number;
  body: string;
}

export function collectDistroTables(topics: TopicInput[]): DistroReport {
  const tables: DistroTable[] = [];
  const skipped: DistroSkip[] = [];

  for (const topic of [...topics].sort((a, b) => a.order - b.order)) {
    const section = sectionBody(topic.body);
    if (section === null) continue;

    const lines = section.split('\n').filter((line) => ROW.test(line));
    if (lines.length < 3) {
      skipped.push({
        topicTitle: topic.title,
        topicHref: topic.href,
        reason: 'the section is prose rather than a table',
      });
      continue;
    }

    const header = splitCells(lines[0]);
    // The first cell of the header is empty: the row labels have no heading.
    const columns = header.slice(1).filter((c) => c.length > 0);

    if (!columns.some((c) => FAMILY_COLUMNS.includes(c))) {
      skipped.push({
        topicTitle: topic.title,
        topicHref: topic.href,
        reason:
          columns.length < 2
            ? 'the section is a note rather than a comparison'
            : `it compares ${columns.join(' against ')}`,
      });
      continue;
    }

    if (columns.length !== 2) {
      skipped.push({
        topicTitle: topic.title,
        topicHref: topic.href,
        reason: `it has ${columns.length} columns rather than two`,
      });
      continue;
    }

    const rows: DistroRow[] = [];
    for (const line of lines.slice(1)) {
      const cells = splitCells(line);
      if (cells.length === 0) continue;
      if (cells.every((c) => SEPARATOR.test(c) || c.length === 0)) continue;
      const [label, ...rest] = cells;
      if (!label) continue;
      rows.push({ label, cells: rest.slice(0, columns.length) });
    }

    if (rows.length === 0) continue;

    tables.push({
      topicTitle: topic.title,
      topicHref: topic.href,
      topicOrder: topic.order,
      columns,
      rows,
    });
  }

  return {
    tables,
    skipped,
    rowCount: tables.reduce((n, t) => n + t.rows.length, 0),
  };
}

/**
 * Very small inline-markdown renderer for table cells.
 *
 * Cells hold backticked commands and the occasional bolded word, and nothing
 * else. Running a full markdown pipeline over a few hundred short strings to
 * support two constructs is not worth the dependency, so this handles those two
 * and escapes everything else.
 */
export function renderCell(text: string): string {
  const escaped = text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
  return escaped
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
}
