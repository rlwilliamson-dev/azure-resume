/**
 * Cross-checks between question banks, topics, and the canonical exam.
 *
 * The per-bank schema in quiz.ts can only see one file at a time. Everything
 * that needs a second source lives here: does a learnRef point at a topic that
 * exists, does a learnAnchor point at a heading that exists, is an objective
 * real, and is a question id unique across the whole track rather than just its
 * own file.
 *
 * The backlink checks matter most. A wrong answer that links to a heading which
 * no longer exists defeats the entire point of the results screen, and it will
 * rot silently every time content is reorganised unless the build catches it.
 *
 * Errors throw. Warnings are returned so the caller can print them, because a
 * thin bank should be visible without blocking a deploy.
 */
import { render } from 'astro:content';
import { getLearnTopics, type LearnTopic } from './learn';
import { getQuizSets, type QuizSet, type QuizQuestion } from './quiz';
import {
  EXAM_FOR_TRACK,
  EXAMS,
  findObjective,
  allObjectives,
  weightedShares,
} from '../config/exams';

/** Tracks whose questions must carry the full certification metadata. */
const STRICT_TRACKS = new Set(Object.keys(EXAM_FOR_TRACK));

/**
 * How many times a domain's weighted share the question pool should hold.
 * A pool equal to the share fills exactly one exam, so every attempt draws all
 * of it and the shuffle only reorders the same items. Three gives a learner
 * meaningfully different attempts.
 */
const POOL_MULTIPLE = 3;

function fail(message: string): never {
  throw new Error(`[quiz] ${message}`);
}

function where(set: QuizSet, question: QuizQuestion): string {
  return `"src/data/quizzes/${set.track}/${set.set}.json" question "${question.id}"`;
}

/** Heading slugs for a topic, from the rendered output rather than guessed. */
async function headingSlugs(topic: LearnTopic): Promise<Set<string>> {
  const { headings } = await render(topic.entry);
  return new Set(headings.map((h) => h.slug));
}

export interface QuizIntegrityReport {
  warnings: string[];
}

export async function assertQuizIntegrity(): Promise<QuizIntegrityReport> {
  const sets = getQuizSets();
  const topics = await getLearnTopics();
  const warnings: string[] = [];

  const topicByKey = new Map(topics.map((t) => [`${t.track}/${t.slug}`, t]));

  /** Resolve a learnRef the same way prerequisites resolve. */
  const resolve = (track: string, ref: string): LearnTopic | undefined =>
    topicByKey.get(ref.includes('/') ? ref : `${track}/${ref}`);

  // Heading slugs are only loaded for topics actually referenced by an anchor,
  // because rendering every topic to validate a handful of links is waste.
  const anchorCache = new Map<string, Set<string>>();

  const idsByTrack = new Map<string, Map<string, string>>();

  for (const set of sets) {
    const strict = STRICT_TRACKS.has(set.track);
    const examId = EXAM_FOR_TRACK[set.track];
    const exam = examId ? EXAMS[examId] : undefined;

    for (const question of set.bank.questions) {
      // --- ids unique across the whole track, not just this bank ---
      const seen = idsByTrack.get(set.track) ?? new Map<string, string>();
      const previous = seen.get(question.id);
      if (previous) {
        fail(
          `${where(set, question)} reuses id "${question.id}", already used in "${previous}". Question ids must be unique across every bank in the "${set.track}" track, because results are aggregated across banks.`
        );
      }
      seen.set(question.id, `src/data/quizzes/${set.track}/${set.set}.json`);
      idsByTrack.set(set.track, seen);

      // --- certification tracks require the full metadata ---
      if (strict) {
        const missing = (['objective', 'learnRef', 'difficulty'] as const).filter(
          (field) => !question[field]
        );
        if (missing.length > 0) {
          fail(
            `${where(set, question)} is missing ${missing.map((m) => `"${m}"`).join(', ')}. Every question in the "${set.track}" track needs an objective, a topic to link back to, and a difficulty.`
          );
        }
      }

      // --- objective and domain must exist on the exam ---
      if (question.objective) {
        if (!exam) {
          fail(
            `${where(set, question)} sets objective "${question.objective}" but the "${set.track}" track has no exam in src/config/exams.ts.`
          );
        }
        const objective = findObjective(exam, question.objective);
        if (!objective) {
          fail(
            `${where(set, question)} targets objective "${question.objective}", which does not exist on ${exam.code}.`
          );
        }
        if (strict && question.domain !== `${objective.domain.id} ${objective.domain.name}`) {
          fail(
            `${where(set, question)} has domain "${question.domain}" but objective ${question.objective} belongs to "${objective.domain.id} ${objective.domain.name}". Domain strings drive the score breakdown, so they must match exactly.`
          );
        }
      }

      // --- the backlink must actually land somewhere ---
      if (question.learnRef) {
        const topic = resolve(set.track, question.learnRef);
        if (!topic) {
          fail(
            `${where(set, question)} links to topic "${question.learnRef}", which does not resolve. Use a slug in the same track ("selinux") or a qualified one ("linux-plus/selinux"). Drafts are absent from a production build.`
          );
        }

        // Beyond-the-exam topics are off-syllabus by definition, so a question
        // pointing at one is either misfiled or is asking about material the
        // certification does not test. Either way it costs a revising reader
        // time they came here to save.
        if (topic.beyondExam) {
          fail(
            `${where(set, question)} links to "${question.learnRef}", which is marked beyondExam. Off-syllabus topics carry no practice questions; point the question at the lesson that covers it, or drop the question.`
          );
        }

        // An exhibit is captured output, so it has to be findable in the topic
        // it came from. Without this the field is an invitation to write a
        // plausible transcript, which is the one thing this repo does not do.
        // Whitespace is normalised on both sides because the JSON carries the
        // block with its own indentation.
        if (question.exhibit) {
          const squash = (s: string) =>
            s
              .split('\n')
              .map((l) => l.trimEnd())
              .join('\n')
              .trim();
          const body = squash(topic.entry.body ?? '');
          const missing = squash(question.exhibit)
            .split('\n')
            .filter((line) => line.trim() && !body.includes(line.trim()));
          if (missing.length) {
            fail(
              `${where(set, question)} shows an exhibit whose lines are not in "${topic.slug}". An exhibit is quoted from a capture on the topic page, not written to look like one. Lines not found: ${missing
                .slice(0, 3)
                .map((l) => JSON.stringify(l.trim()))
                .join(', ')}`
            );
          }
        }

        // Provenance is not the only way an exhibit goes wrong. A slice taken
        // from the first line of one capture to the last line of another passes
        // line by line and is nonsense as a whole, which happened twice while
        // these were being written. A fence or a sentence in the middle is the
        // signature of that mistake.
        if (question.exhibit) {
          const lines = question.exhibit.split('\n');
          const fence = lines.find((l) => l.trim().startsWith('```'));
          if (fence) {
            fail(
              `${where(set, question)} has a code fence inside its exhibit, which means the slice ran past the end of one capture and into the page around it.`
            );
          }
          const prose = lines.find(
            (l) => l.length > 60 && /[.?]$/.test(l.trimEnd()) && !/^\s*[$>#]/.test(l)
          );
          if (prose) {
            fail(
              `${where(set, question)} has a sentence inside its exhibit: ${JSON.stringify(prose.trim().slice(0, 60))}. An exhibit is captured output, so prose in it means the slice picked up the surrounding text.`
            );
          }
        }

        if (question.learnAnchor) {
          const key = `${topic.track}/${topic.slug}`;
          let slugs = anchorCache.get(key);
          if (!slugs) {
            slugs = await headingSlugs(topic);
            anchorCache.set(key, slugs);
          }
          if (!slugs.has(question.learnAnchor)) {
            const sample = [...slugs].slice(0, 8).join(', ');
            fail(
              `${where(set, question)} links to anchor "#${question.learnAnchor}" in "${topic.slug}", which has no such heading. Headings there include: ${sample}${slugs.size > 8 ? ', ...' : ''}`
            );
          }
        }
      } else if (question.learnAnchor) {
        fail(
          `${where(set, question)} sets "learnAnchor" without a "learnRef". An anchor needs a topic to be an anchor in.`
        );
      }

      // --- item quality, warnings only ---
      const correctText = question.options
        .filter((o) => question.correct.includes(o.id))
        .map((o) => o.text.length);
      const otherText = question.options
        .filter((o) => !question.correct.includes(o.id))
        .map((o) => o.text.length);
      if (correctText.length > 0 && otherText.length > 0) {
        const avgCorrect = correctText.reduce((a, b) => a + b, 0) / correctText.length;
        const avgOther = otherText.reduce((a, b) => a + b, 0) / otherText.length;
        if (avgCorrect > avgOther * 1.5 && avgCorrect - avgOther > 20) {
          warnings.push(
            `${where(set, question)}: the correct option is much longer than the distractors (${Math.round(avgCorrect)} vs ${Math.round(avgOther)} characters). Length is a giveaway; even the options out.`
          );
        }
      }

      // Only flag a genuinely negative ask. A bare "not" is usually part of a
      // quoted error string ("Operation not permitted"), which is content
      // rather than a negative stem, so match the auxiliary-verb shape instead.
      if (
        /\b(is|are|was|were|does|do|did|would|should|can|will)\s+not\b/i.test(question.prompt) ||
        /\bexcept\b/i.test(question.prompt)
      ) {
        warnings.push(
          `${where(set, question)}: the stem asks a negative question. Word stems positively, or capitalise the NOT so nobody misses it.`
        );
      }

      const mentionsDistractor = question.options
        .filter((o) => !question.correct.includes(o.id))
        .some((o) => {
          const firstWords = o.text.split(/\s+/).slice(0, 3).join(' ').replace(/[^\w\s-]/g, '');
          return firstWords.length > 3 && question.explanation.includes(firstWords);
        });
      if (!mentionsDistractor && question.explanation.length < 240) {
        warnings.push(
          `${where(set, question)}: the explanation is short and does not appear to address any wrong option. An explanation that only justifies the answer teaches one fact.`
        );
      }
    }

    // --- bank-level shape ---
    //
    // The old wording asserted that the exam is scenario-based, which was true
    // of the only exam here when it was written and is false for domain 1 of
    // N10-009: seven of its eight objectives open on Explain, Compare and
    // contrast, or Summarize. So the warning states what the objectives for
    // this bank's own domains actually say instead of making a claim about the
    // whole exam. Objective verb is being used as a proxy for the cognitive
    // level of an item; CompTIA publishes no mapping between the two.
    if (strict) {
      const levels = set.bank.questions.map((q) => q.difficulty);
      const recall = levels.filter((d) => d === 'recall').length;
      if (recall > set.bank.questions.length / 2) {
        const domainIds = new Set(
          set.bank.questions
            .map((q) => (exam && q.objective ? findObjective(exam, q.objective)?.domain.id : undefined))
            .filter((id): id is string => Boolean(id))
        );
        const objectives = (exam?.domains ?? [])
          .filter((d) => domainIds.has(d.id))
          .flatMap((d) => d.objectives);
        const scenario = objectives.filter((o) => /^Given a scenario/i.test(o.title)).length;
        const shape =
          objectives.length === 0
            ? 'Weight the bank toward application and analysis.'
            : `${scenario} of ${objectives.length} objective${objectives.length === 1 ? '' : 's'} in this bank's domain open on "Given a scenario", so weight it accordingly.`;
        warnings.push(
          `"src/data/quizzes/${set.track}/${set.set}.json": ${recall} of ${set.bank.questions.length} questions are "recall". ${shape}`
        );
      }
    }
  }

  // --- coverage warnings, per track ---
  for (const [track, examId] of Object.entries(EXAM_FOR_TRACK)) {
    const exam = EXAMS[examId];
    if (!exam) continue;

    const questions = sets.filter((s) => s.track === track).flatMap((s) => s.bank.questions);
    if (questions.length === 0) continue;

    const byObjective = new Map<string, number>();
    for (const q of questions) {
      if (q.objective) byObjective.set(q.objective, (byObjective.get(q.objective) ?? 0) + 1);
    }

    const shares = weightedShares(exam);

    for (const domain of exam.domains) {
      const inDomain = domain.objectives.reduce((n, o) => n + (byObjective.get(o.id) ?? 0), 0);
      const target = shares.get(domain.id) ?? 0;
      if (inDomain < target) {
        warnings.push(
          `${exam.code} domain ${domain.id} (${domain.name}) has ${inDomain} question${inDomain === 1 ? '' : 's'} against a weighted share of ${target}. A weighted full exam cannot fill it without repeating.`
        );
      } else if (inDomain < target * POOL_MULTIPLE) {
        // Meeting the share exactly means one full exam consumes the whole pool,
        // so every attempt is the same questions in a different order. Shuffling
        // then hides nothing, which is the opposite of what it is for. Aim for a
        // pool several times the share so repeat attempts genuinely differ.
        warnings.push(
          `${exam.code} domain ${domain.id} (${domain.name}) has ${inDomain} against a weighted share of ${target}. That fills an exam but leaves little variety on a second attempt; ${target * POOL_MULTIPLE} would give a pool ${POOL_MULTIPLE} times the share.`
        );
      }
    }

    const empty = allObjectives(exam).filter((o) => !byObjective.has(o.id));
    if (empty.length > 0) {
      warnings.push(
        `${exam.code} has ${empty.length} objective${empty.length === 1 ? '' : 's'} with no questions: ${empty.map((o) => o.id).join(', ')}.`
      );
    }
  }

  return { warnings };
}
