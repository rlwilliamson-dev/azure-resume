import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

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
  }),
});

export const collections = { posts, learn };
