/**
 * Question banks live in src/data/quizzes/<track>/<set>.json and are validated
 * here at build time. A malformed bank throws during `astro build` rather than
 * rendering a broken page, so bad data cannot reach production.
 *
 * The engine is track-agnostic. Dropping a JSON file into a track directory
 * creates a practice route for that track.
 */
import { z } from 'astro:content';
import { LEARN_BASE } from '../config/site';

const optionSchema = z.object({
  id: z.string().min(1),
  text: z.string().min(1),
});

const questionSchema = z
  .object({
    id: z.string().min(1),
    prompt: z.string().min(1),
    /** Exam domain, used for the per-domain score breakdown. */
    domain: z.string().min(1),
    options: z.array(optionSchema).min(2),
    /**
     * Ids of the correct options. One id is a single-answer question, more than
     * one is a multiple-answer question.
     */
    correct: z.array(z.string().min(1)).min(1),
    explanation: z.string().min(1),
  })
  .superRefine((question, ctx) => {
    const optionIds = question.options.map((o) => o.id);

    const duplicateOption = optionIds.find((id, i) => optionIds.indexOf(id) !== i);
    if (duplicateOption) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: `question "${question.id}" has two options with id "${duplicateOption}"`,
      });
    }

    const duplicateCorrect = question.correct.find((id, i) => question.correct.indexOf(id) !== i);
    if (duplicateCorrect) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: `question "${question.id}" lists correct answer "${duplicateCorrect}" twice`,
      });
    }

    for (const id of question.correct) {
      if (!optionIds.includes(id)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: `question "${question.id}" marks "${id}" correct, but no option has that id`,
        });
      }
    }

    if (question.correct.length === question.options.length) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: `question "${question.id}" marks every option correct, which cannot be answered wrong`,
      });
    }
  });

export const bankSchema = z.object({
  title: z.string().min(1),
  description: z.string().min(1),
  track: z.string().min(1),
  questions: z.array(questionSchema).min(1),
});

export type QuizBank = z.infer<typeof bankSchema>;
export type QuizQuestion = QuizBank['questions'][number];

export interface QuizSet {
  /** Track slug, taken from the containing directory. */
  track: string;
  /** Set slug, taken from the filename. */
  set: string;
  href: string;
  bank: QuizBank;
}

const bankModules = import.meta.glob<unknown>('../data/quizzes/**/*.json', { eager: true });

let cached: QuizSet[] | null = null;

/**
 * Load and validate every question bank. Throws with the offending file path if
 * a bank does not match the schema.
 */
export function getQuizSets(): QuizSet[] {
  if (cached) return cached;

  const sets: QuizSet[] = [];

  for (const [path, mod] of Object.entries(bankModules)) {
    const match = path.match(/\/quizzes\/([^/]+)\/([^/]+)\.json$/);
    if (!match) {
      throw new Error(
        `[quiz] "${path}" is not in the expected location. Banks must be src/data/quizzes/<track>/<set>.json`
      );
    }
    const [, track, set] = match as unknown as [string, string, string];

    const raw = (mod as { default?: unknown }).default ?? mod;
    const parsed = bankSchema.safeParse(raw);

    if (!parsed.success) {
      const detail = parsed.error.issues
        .map((issue) => `  - ${issue.path.join('.') || '(root)'}: ${issue.message}`)
        .join('\n');
      throw new Error(`[quiz] "${path}" failed validation:\n${detail}`);
    }

    if (parsed.data.track !== track) {
      throw new Error(
        `[quiz] "${path}" declares track "${parsed.data.track}" but sits in the "${track}" directory. Make them match, or move the file.`
      );
    }

    const ids = parsed.data.questions.map((q) => q.id);
    const duplicate = ids.find((id, i) => ids.indexOf(id) !== i);
    if (duplicate) {
      throw new Error(`[quiz] "${path}" has two questions with id "${duplicate}"`);
    }

    sets.push({
      track,
      set,
      href: `${LEARN_BASE}/${track}/practice/${set}`,
      bank: parsed.data,
    });
  }

  sets.sort((a, b) => a.track.localeCompare(b.track) || a.set.localeCompare(b.set));
  cached = sets;
  return sets;
}

/** Practice sets belonging to one track. */
export function quizSetsForTrack(track: string): QuizSet[] {
  return getQuizSets().filter((s) => s.track === track);
}

/** Distinct exam domains in a bank, in first-seen order. */
export function domainsIn(bank: QuizBank): string[] {
  return Array.from(new Set(bank.questions.map((q) => q.domain)));
}
