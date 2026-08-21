/**
 * Everything the /learn routes know about tracks and topics is derived here,
 * from the content collection on disk. Adding a Markdown file adds a page.
 * Adding a directory adds a track. No route, index, or navigation array needs
 * to be edited by hand.
 *
 * Consistency problems (a frontmatter track that disagrees with its directory,
 * two topics claiming the same order, a prerequisite pointing at nothing) throw
 * during the build rather than shipping a broken page.
 */
import { getCollection, type CollectionEntry } from 'astro:content';
import { trackMetaFor } from '../config/tracks';
import { LEARN_BASE } from '../config/site';
import { getQuizSets } from './quiz';
import { EXAMS, findObjective } from '../config/exams';

export type LearnEntry = CollectionEntry<'learn'>;

export type Level = 'intro' | 'working' | 'deep';

/**
 * Levels in increasing difficulty. Topics are listed in reading order rather
 * than grouped by level, so this is the badge ordering, not a section ordering.
 */
export const LEVELS: readonly Level[] = ['intro', 'working', 'deep'] as const;

export const LEVEL_LABELS: Record<Level, string> = {
  intro: 'Intro',
  working: 'Working knowledge',
  deep: 'Deep dive',
};

/** One certification objective a topic claims to cover. */
export interface TopicExamObjective {
  exam: string;
  domain: string;
  objective: string;
}

/** One citation backing the claims in a topic. */
export interface TopicSource {
  title: string;
  url: string;
  publisher: string;
  accessed: Date;
  tier: number;
}

/** One observable symptom a topic explains. */
export interface TopicSymptom {
  symptom: string;
  anchor?: string;
}

/**
 * How long the page takes to read, in minutes, with every collapsible panel
 * open. Prose and captured output are not read at the same speed, so they are
 * counted separately.
 *
 * Prose runs at 240 words per minute, a common figure for adults reading
 * non-fiction attentively. Fenced blocks are counted by line at 25 lines per
 * minute, because a captured transcript is studied rather than skimmed and a
 * line of it carries more than a line of prose.
 *
 * The estimate assumes the reader opens the DEEPER and Check yourself panels,
 * which is what the page is for. Somebody reading only the main flow will be
 * quicker, and that is the right direction for an estimate to be wrong in.
 */
export function readingMinutes(body: string): number {
  const lines = body.split('\n');
  let prose = 0;
  let code = 0;
  let inFence = false;

  for (const line of lines) {
    if (/^\s*```/.test(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) {
      code += 1;
      continue;
    }
    // Markup carries no reading time; a table row or a heading marker is not a word.
    const text = line
      .replace(/<\/?[^>]+>/g, ' ')
      .replace(/[|#>*_`[\]()-]/g, ' ')
      .trim();
    if (text) prose += text.split(/\s+/).length;
  }

  const minutes = prose / 240 + code / 25;
  return Math.max(1, Math.round(minutes));
}

export interface LearnTopic {
  entry: LearnEntry;
  /** Track slug, taken from the containing directory. */
  track: string;
  /** URL slug, the filename with any leading "NN-" ordering prefix removed. */
  slug: string;
  href: string;
  title: string;
  description: string;
  /** The line under the heading. Falls back to `description` when absent. */
  deck?: string;
  level: Level;
  order: number;
  objectives: string[];
  prerequisites: string[];
  tags: string[];
  updated: Date;
  draft: boolean;
  examObjectives: TopicExamObjective[];
  sources: TopicSource[];
  symptoms: TopicSymptom[];
  orientation: boolean;
  /** Off-syllabus material. Numbered outside the lessons, never quizzed. */
  beyondExam: boolean;
  /** Estimated minutes to read the whole page, panels open. See readingMinutes. */
  readingMinutes: number;
}

export interface LearnTrack {
  slug: string;
  name: string;
  description: string;
  position: number;
  href: string;
  topics: LearnTopic[];
}

export interface PrerequisiteLink {
  label: string;
  href: string;
}

/** Strip a leading "01-" style ordering prefix from a filename. */
function stripOrderPrefix(name: string): string {
  return name.replace(/^\d+[-_]/, '');
}

function fail(message: string): never {
  throw new Error(`[learn] ${message}`);
}

/**
 * Load every topic, newest schema validation already applied by the collection.
 * Drafts are included in `astro dev` and excluded from `astro build`, matching
 * how the blog collection behaves.
 */
export async function getLearnTopics(): Promise<LearnTopic[]> {
  const showDrafts = import.meta.env.DEV;
  const entries = await getCollection('learn', ({ data }) => showDrafts || !data.draft);

  const topics: LearnTopic[] = entries.map((entry) => {
    const segments = entry.id.split('/');

    if (segments.length === 1) {
      fail(
        `"${entry.id}.md" sits at the root of src/content/learn. Every topic must live in a track directory, for example src/content/learn/bicep/${entry.id}.md`
      );
    }
    if (segments.length > 2) {
      fail(
        `"${entry.id}.md" is nested more than one directory deep. Topics must be exactly src/content/learn/<track>/<file>.md`
      );
    }

    const [track, filename] = segments as [string, string];
    const slug = stripOrderPrefix(filename);

    if (entry.data.track !== track) {
      fail(
        `"${entry.id}.md" has frontmatter track "${entry.data.track}" but lives in the "${track}" directory. Make them match, or move the file.`
      );
    }

    return {
      entry,
      track,
      slug,
      href: `${LEARN_BASE}/${track}/${slug}`,
      title: entry.data.title,
      description: entry.data.description,
      deck: entry.data.deck,
      level: entry.data.level,
      order: entry.data.order,
      objectives: entry.data.objectives,
      prerequisites: entry.data.prerequisites,
      tags: entry.data.tags,
      updated: entry.data.updated,
      draft: entry.data.draft,
      examObjectives: entry.data.examObjectives,
      sources: entry.data.sources,
      symptoms: entry.data.symptoms,
      orientation: entry.data.orientation,
      beyondExam: entry.data.beyondExam,
      readingMinutes: readingMinutes(entry.body ?? ''),
    };
  });

  assertNoCollisions(topics);
  assertPrerequisitesResolve(topics);
  assertExamObjectivesResolve(topics);
  assertCertificationTopicsCite(topics);

  return topics;
}

function assertNoCollisions(topics: LearnTopic[]): void {
  const bySlug = new Map<string, string>();
  const byOrder = new Map<string, string>();

  for (const topic of topics) {
    const slugKey = `${topic.track}/${topic.slug}`;
    const existingSlug = bySlug.get(slugKey);
    if (existingSlug) {
      fail(
        `"${topic.entry.id}.md" and "${existingSlug}.md" both resolve to the URL ${topic.href}. Ordering prefixes are stripped from URLs, so two files in a track cannot share a name after the prefix.`
      );
    }
    bySlug.set(slugKey, topic.entry.id);

    const orderKey = `${topic.track}#${topic.order}`;
    const existingOrder = byOrder.get(orderKey);
    if (existingOrder) {
      fail(
        `"${topic.entry.id}.md" and "${existingOrder}.md" both claim order ${topic.order} in the "${topic.track}" track. Ordering would be ambiguous, so pick distinct values. Numbering in tens leaves room to insert.`
      );
    }
    byOrder.set(orderKey, topic.entry.id);
  }
}

function assertPrerequisitesResolve(topics: LearnTopic[]): void {
  const index = new Set(topics.map((t) => `${t.track}/${t.slug}`));

  for (const topic of topics) {
    for (const ref of topic.prerequisites) {
      const key = ref.includes('/') ? ref : `${topic.track}/${ref}`;
      if (!index.has(key)) {
        fail(
          `"${topic.entry.id}.md" lists prerequisite "${ref}", which does not resolve to a topic. Use a slug in the same track ("resources-and-scopes") or a qualified one ("bicep/resources-and-scopes"). Note that drafts are not present during a production build.`
        );
      }
    }
  }
}

/**
 * Every objective a topic claims must exist in the canonical exam definition,
 * and the domain it names must be the one that objective actually belongs to.
 * A typo here would otherwise show up as a silent hole in the coverage report,
 * which is the one page whose whole job is to make holes visible.
 */
function assertExamObjectivesResolve(topics: LearnTopic[]): void {
  for (const topic of topics) {
    for (const ref of topic.examObjectives) {
      const exam = EXAMS[ref.exam];
      if (!exam) {
        fail(
          `"${topic.entry.id}.md" claims objective "${ref.objective}" on exam "${ref.exam}", which is not defined. Known exams: ${Object.keys(EXAMS).join(', ')}. Add it to src/config/exams.ts.`
        );
      }

      const objective = findObjective(exam, ref.objective);
      if (!objective) {
        fail(
          `"${topic.entry.id}.md" claims objective "${ref.objective}", which does not exist on ${exam.code}. Check src/config/exams.ts for the objective numbers.`
        );
      }

      if (objective.domain.id !== ref.domain) {
        fail(
          `"${topic.entry.id}.md" puts objective "${ref.objective}" in domain "${ref.domain}", but on ${exam.code} it belongs to domain "${objective.domain.id}" (${objective.domain.name}).`
        );
      }
    }

    const seen = new Set<string>();
    for (const ref of topic.examObjectives) {
      const key = `${ref.exam}/${ref.objective}`;
      if (seen.has(key)) {
        fail(`"${topic.entry.id}.md" lists objective "${ref.objective}" twice.`);
      }
      seen.add(key);
    }
  }
}

/**
 * Certification content has to cite. A topic that claims to cover an exam
 * objective is making factual claims about command behavior, default values,
 * and file paths, and those need a source someone can check.
 *
 * Deliberately scoped to topics with exam objectives, so notes written before
 * this rule existed are not retroactively broken.
 */
function assertCertificationTopicsCite(topics: LearnTopic[]): void {
  for (const topic of topics) {
    if (topic.examObjectives.length > 0 && topic.sources.length === 0) {
      fail(
        `"${topic.entry.id}.md" claims exam coverage (${topic.examObjectives
          .map((o) => o.objective)
          .join(', ')}) but has no "sources". Certification topics must cite at least one source: add a sources entry with title, url, publisher, accessed, and tier.`
      );
    }
  }
}

/** Topics for one track, sorted by order. */
export function topicsForTrack(topics: LearnTopic[], track: string): LearnTopic[] {
  return topics.filter((t) => t.track === track).sort((a, b) => a.order - b.order);
}

/**
 * Every track, sorted by configured position.
 *
 * A track exists once it has at least one topic, or at least one practice bank
 * under src/data/quizzes. The second case lets a track ship practice questions
 * before its notes are written, without anyone registering it by hand.
 */
export async function getLearnTracks(): Promise<LearnTrack[]> {
  const topics = await getLearnTopics();
  const slugs = Array.from(
    new Set([...topics.map((t) => t.track), ...getQuizSets().map((s) => s.track)])
  );

  return slugs
    .map((slug) => {
      const meta = trackMetaFor(slug);
      return {
        slug,
        name: meta.name,
        description: meta.description,
        position: meta.position,
        href: `${LEARN_BASE}/${slug}`,
        topics: topicsForTrack(topics, slug),
      };
    })
    .sort((a, b) => a.position - b.position || a.name.localeCompare(b.name));
}

/**
 * Display numbers for a track, in reading order.
 *
 * Orientation pages number 00 and are not counted, so the first actual lesson
 * is 01 no matter how many front-matter pages sit ahead of it. Zero-padded to
 * the width of the lesson count, so a forty-topic track reads 01 through 40.
 */
export function lessonNumbers(trackTopics: LearnTopic[]): Map<string, string> {
  const lessonCount = trackTopics.filter(isLesson).length;
  const width = Math.max(2, String(lessonCount).length);
  const numbers = new Map<string, string>();

  let n = 0;
  for (const topic of trackTopics) {
    if (topic.beyondExam) {
      numbers.set(topic.slug, '');
    } else if (topic.orientation) {
      numbers.set(topic.slug, '0'.repeat(width));
    } else {
      n += 1;
      numbers.set(topic.slug, String(n).padStart(width, '0'));
    }
  }
  return numbers;
}

/** A numbered lesson: not the orientation page, and not off-syllabus material. */
function isLesson(topic: LearnTopic): boolean {
  return !topic.orientation && !topic.beyondExam;
}

/**
 * How many topics in a track are numbered lessons.
 *
 * Front matter and beyond-the-exam topics are both excluded, so "lesson 40 of
 * 76" counts the same 76 whatever else the track carries.
 */
export function lessonCount(trackTopics: LearnTopic[]): number {
  return trackTopics.filter(isLesson).length;
}

/** Previous and next topic within the same track, by order. */
export function getNeighbors(
  trackTopics: LearnTopic[],
  slug: string
): { prev: LearnTopic | null; next: LearnTopic | null } {
  const i = trackTopics.findIndex((t) => t.slug === slug);
  if (i === -1) return { prev: null, next: null };
  return {
    prev: i > 0 ? (trackTopics[i - 1] as LearnTopic) : null,
    next: i < trackTopics.length - 1 ? (trackTopics[i + 1] as LearnTopic) : null,
  };
}

/**
 * Turn a topic's prerequisite refs into links. Refs are validated during load,
 * so every ref resolves by the time this runs.
 */
export function resolvePrerequisites(
  topic: LearnTopic,
  allTopics: LearnTopic[]
): PrerequisiteLink[] {
  return topic.prerequisites.map((ref) => {
    const key = ref.includes('/') ? ref : `${topic.track}/${ref}`;
    const match = allTopics.find((t) => `${t.track}/${t.slug}` === key) as LearnTopic;
    return { label: match.title, href: match.href };
  });
}
