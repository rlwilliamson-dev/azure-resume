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
    /**
     * Certification objective this question targets, for example "1.3".
     * Optional so the Security+ banks keep validating. The coverage report
     * counts questions per objective from this, which is why it exists ahead of
     * the rest of the certification fields.
     */
    objective: z.string().min(1).optional(),
    /**
     * Preamble for a scenario-style item. CompTIA's performance-based questions
     * put the system in a described state and then ask for a task; this carries
     * that state so the prompt itself stays short.
     */
    scenario: z.string().min(1).optional(),
    /**
     * Captured output the question is asked about, rendered as a monospace
     * block above the prompt. This is the closest a static page gets to the
     * exam's performance-based items: the reader is given the same artefact a
     * technician would have and asked what it proves.
     *
     * It has to be real. quiz-validate.ts checks that the text appears in the
     * topic named by `learnRef`, so an exhibit is a quotation from a capture
     * the toolchain produced rather than a plausible-looking invention.
     */
    exhibit: z.string().min(1).optional(),
    /**
     * Topic that explains this question, resolved like `prerequisites`: a bare
     * slug stays in the same track, a qualified one crosses tracks. Drives the
     * backlink from a wrong answer to the material.
     */
    learnRef: z.string().min(1).optional(),
    /** Heading anchor within that topic, without the leading '#'. */
    learnAnchor: z.string().min(1).optional(),
    /**
     * Cognitive level. A bank weighted toward `recall` does not prepare anyone
     * for a scenario-based exam, which is what the build warns about.
     */
    difficulty: z.enum(['recall', 'application', 'analysis']).optional(),
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

    // Item-writing rules from the authoring standard
    // (docs/linux-plus-question-authoring-standard.md). These are the ones
    // cheap enough to check mechanically, so integrity is structural rather
    // than a promise in a document.

    for (const option of question.options) {
      if (/^\s*(all|none)\s+of\s+the\s+above\s*\.?\s*$/i.test(option.text)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: `question "${question.id}" uses "${option.text.trim()}" as an option. Haladyna guideline 26 says avoid all-of-the-above; none-of-the-above mostly adds difficulty without measuring anything. Write a real distractor.`,
        });
      }
    }

    // Nothing on this site may present itself as reproducing real exam content.
    // CompTIA's Candidate Agreement prohibits disseminating actual exam content
    // by any means, and claiming to is its own problem.
    const BANNED = /\b(brain\s?dump|braindump|actual exam question|real exam question|actual test question|leaked (?:exam|question))/i;
    const fields: Array<[string, string]> = [
      ['prompt', question.prompt],
      ['explanation', question.explanation],
      ...(question.scenario ? ([['scenario', question.scenario]] as Array<[string, string]>) : []),
      ...question.options.map((o): [string, string] => [`option "${o.id}"`, o.text]),
    ];
    for (const [where, text] of fields) {
      const hit = text.match(BANNED);
      if (hit) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: `question "${question.id}" ${where} contains "${hit[0]}". Practice items here are original work written from published objectives and must never present themselves otherwise.`,
        });
      }
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
