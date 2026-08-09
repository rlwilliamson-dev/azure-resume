import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';
import { EXAM_IDS } from './config/exams';

const posts = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/posts' }),
  schema: ({ image }) => z.object({
    title: z.string().max(120),
    description: z.string().max(300),
    publishDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    tags: z.array(z.string()).default([]),
    heroImage: image().optional(),
    heroImageAlt: z.string().optional(),
    canonicalUrl: z.string().url().optional(),
    draft: z.boolean().default(false),
  }),
});

// Learning notes, one directory per track. The directory name is the track
// slug; display metadata for a track is an optional override in
// src/config/tracks.ts. Files whose name starts with an underscore are
// excluded so _template.md never builds.
const learn = defineCollection({
  loader: glob({ pattern: ['**/*.md', '!**/_*.md'], base: './src/content/learn' }),
  schema: z.object({
    title: z.string().max(120),
    description: z.string().max(300),
    track: z.string(),
    level: z.enum(['intro', 'working', 'deep']),
    order: z.number(),
    objectives: z.array(z.string()).min(1),
    prerequisites: z.array(z.string()).default([]),
    tags: z.array(z.string()).default([]),
    updated: z.coerce.date(),
    draft: z.boolean().default(false),

    /**
     * Certification objectives this topic covers. Drives the coverage report and
     * lets a practice question link back to the material. Validated against
     * src/config/exams.ts during the build, so a typo in an objective number
     * fails rather than producing a silent coverage gap.
     */
    examObjectives: z
      .array(
        z.object({
          exam: z.enum(EXAM_IDS),
          /** Domain number, for example "1.0". */
          domain: z.string(),
          /** Objective number, for example "1.3". */
          objective: z.string(),
        })
      )
      .default([]),

    /**
     * Where the claims in this topic come from. Empty by default so the notes
     * written before this field existed keep building, but any topic that
     * claims exam coverage must cite at least one source. That rule lives in
     * lib/learn.ts.
     */
    sources: z
      .array(
        z.object({
          title: z.string(),
          url: z.string().url(),
          publisher: z.string(),
          accessed: z.coerce.date(),
          /** 1 = primary (vendor docs, man pages), 2 = high-quality secondary. */
          tier: z.number().int().min(1).max(2),
        })
      )
      .default([]),

    /**
     * A front-matter page rather than a lesson: orientation, exam mechanics,
     * how to use the track. It numbers as 00, sits outside the lesson count so
     * the first real lesson is 01, and renders a generated contents listing for
     * the whole track after its body.
     */
    orientation: z.boolean().default(false),

    /**
     * Observable symptoms this topic explains, for the symptom index. Written as
     * the thing you actually see, error text included, because that is what
     * somebody searches for at 2am.
     *
     * Reserved: the index route is not built yet. Populating this now avoids a
     * migration later.
     */
    symptoms: z
      .array(
        z.object({
          symptom: z.string(),
          /** Heading anchor within this topic, without the leading '#'. */
          anchor: z.string().optional(),
        })
      )
      .default([]),
  }),
});

export const collections = { posts, learn };
