/**
 * Pulls a track's comparison tables out of topic bodies.
 *
 * Which heading to look under, and which column names count as a thing being
 * compared, are declared per track in config/tracks.ts. Linux+ compares RHEL
 * against Debian; Network+ compares Linux against Windows against macOS, and a
 * vendor CLI against a host. Nothing about either is hardcoded here.
 *
 * These tables are the densest revision material a vendor-neutral exam has and
 * the most scattered inside the track, one table at a time across seventy-odd
 * lessons. Reading them together is a different job from reading any one topic,
 * so the reference page collects them.
 *
 * Extracted from the markdown rather than maintained by hand, because a
 * hand-written cheat sheet drifts from the topics the moment either one is
 * edited, and the drift is invisible.
 *
 * Not every section under that heading holds a comparison. A few are a note or
 * prose with no table. Those stay in their topic and are simply not collected,
 * because a reference page listing what it chose not to show you is worse than
 * one that shows less.
 */
import type { CompareMeta } from '../config/tracks';

export interface CompareRow {
  /** The left-hand cell: what is being compared. */
  label: string;
  /** One cell per family column, in the order the source table lists them. */
  cells: string[];
}

export interface CompareTable {
  topicTitle: string;
  topicHref: string;
  topicOrder: number;
  /** Column headings, minus the empty leading cell. */
  columns: string[];
  rows: CompareRow[];
}

export interface CompareReport {
  tables: CompareTable[];
  rowCount: number;
}

/** A markdown table row: leading and trailing pipes, cells between. */
const ROW = /^\|(.*)\|\s*$/;

/** The separator row markdown uses under a header, such as | --- | --- |. */
const SEPARATOR = /^[\s|:-]+$/;

function splitCells(line: string): string[] {
  const match = ROW.exec(line);
  if (!match) return [];
  return match[1].split('|').map((cell) => cell.trim());
}

/** The body text between the track's comparison heading and the next h2. */
function sectionBody(body: string, heading: string): string | null {
  const section = new RegExp(`^## ${heading}\\s*$`, 'm');
  const start = section.exec(body);
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

export function collectCompareTables(topics: TopicInput[], meta: CompareMeta): CompareReport {
  const tables: CompareTable[] = [];
  const isCompared = (heading: string) => meta.columnPattern.test(heading.trim());

  for (const topic of [...topics].sort((a, b) => a.order - b.order)) {
    const section = sectionBody(topic.body, meta.heading);
    if (section === null) continue;

    const lines = section.split('\n').filter((line) => ROW.test(line));
    if (lines.length < 3) continue;

    const header = splitCells(lines[0]);
    // The row-label column usually has an empty heading. When a topic gives it
    // one ("Task", "To check that"), that heading names the row rather than a
    // thing being compared, so it is dropped along with the empty case.
    const all = header.filter((c) => c.length > 0);
    const columns = all.filter((c) => !meta.labelHeadings.includes(c));

    // Two or three columns both compare fine; the table just gets another one.
    // Anything not comparing what this track compares is left in its topic
    // without comment, because a reader does not need a list of things this page
    // decided against showing them.
    if (columns.length < 2 || !columns.some(isCompared)) continue;

    const rows: CompareRow[] = [];
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
