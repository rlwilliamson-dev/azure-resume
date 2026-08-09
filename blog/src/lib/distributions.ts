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
 * Not every "Across distributions" section compares distributions. A few are a
 * note, a shell comparison, or prose with no table. Those stay in their topic
 * and are simply not collected, because a reference page listing what it chose
 * not to show you is worse than one that shows less.
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

export interface DistroReport {
  tables: DistroTable[];
  rowCount: number;
}

/** Section heading the tables live under. */
const SECTION = /^## Across distributions\s*$/m;

/** A markdown table row: leading and trailing pipes, cells between. */
const ROW = /^\|(.*)\|\s*$/;

/** The separator row markdown uses under a header, such as | --- | --- |. */
const SEPARATOR = /^[\s|:-]+$/;

/**
 * Headings that name a distribution or a family rather than a row label. A
 * table qualifies when at least one column matches, which lets through the
 * three-way splits and the ones headed with a concrete version.
 */
const DISTRIBUTIONS =
  /^(RHEL|Debian|RPM|dpkg|Ubuntu|SUSE|openSUSE|SLES|AlmaLinux|Rocky|Fedora|CentOS)\b/i;

const looksLikeDistribution = (heading: string) => DISTRIBUTIONS.test(heading.trim());

/** Headings on the row-label column, which is not a distribution. */
const LABEL_HEADINGS = ['To check that'];

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

  for (const topic of [...topics].sort((a, b) => a.order - b.order)) {
    const section = sectionBody(topic.body);
    if (section === null) continue;

    const lines = section.split('\n').filter((line) => ROW.test(line));
    if (lines.length < 3) continue;

    const header = splitCells(lines[0]);
    // The row-label column usually has an empty heading. When a topic gives it
    // one ("To check that"), that heading is a label rather than a distribution,
    // so it is dropped along with the empty case.
    const all = header.filter((c) => c.length > 0);
    const columns = all.filter((c) => !LABEL_HEADINGS.includes(c));

    // Two or three distributions both compare fine; the table just gets another
    // column. Anything that is not comparing distributions is left in its topic
    // without comment, because a reader does not need a list of things this page
    // decided against showing them.
    if (columns.length < 2 || !columns.some(looksLikeDistribution)) continue;

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
