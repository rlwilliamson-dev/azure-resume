/**
 * Adds an AVIF layer to the images in the learn section.
 *
 * Astro already routes Markdown images through its optimization pipeline: it
 * emits WebP with explicit width and height and loading="lazy". That covers
 * layout shift and lazy loading. What it does not do for plain .md content is
 * emit a <picture> with an AVIF source, because components cannot be used
 * inside .md.
 *
 * So this runs after the build: for every optimized raster image referenced by
 * a page under /learn, generate an AVIF sibling with sharp (already a
 * dependency, used by Astro's image service) and wrap the <img> in a <picture>
 * that offers AVIF first and falls back to the existing WebP. Browsers without
 * AVIF support ignore the source and use the img untouched.
 *
 * An AVIF that comes out no smaller than its WebP is discarded, so a page never
 * ships a larger file than it would have without this step.
 */
import { readFile, writeFile, readdir, stat, unlink } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

/** Matches an img tag while respecting quoted attribute values. */
const IMG_TAG = /<img\s+((?:[^>"']|"[^"]*"|'[^']*')*)\/?>/g;
const RASTER = /\.(png|jpe?g|webp)$/i;

async function walk(dir) {
  const out = [];
  let entries;
  try {
    entries = await readdir(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...(await walk(full)));
    else if (entry.name.endsWith('.html')) out.push(full);
  }
  return out;
}

function getAttr(attrs, name) {
  const match = attrs.match(new RegExp(`${name}\\s*=\\s*"([^"]*)"`, 'i'));
  return match ? match[1] : null;
}

export default function learnImages({ sectionDir = 'learn', quality = 50 } = {}) {
  return {
    name: 'learn-images-avif',
    hooks: {
      'astro:build:done': async ({ dir, logger }) => {
        const outRoot = fileURLToPath(dir);
        const sectionRoot = path.join(outRoot, sectionDir);
        if (!existsSync(sectionRoot)) return;

        const { default: sharp } = await import('sharp');
        const pages = await walk(sectionRoot);

        /** Cache keyed by source path so a shared image is only converted once. */
        const avifFor = new Map();
        let wrapped = 0;

        for (const page of pages) {
          const html = await readFile(page, 'utf8');
          let changed = false;

          const next = await replaceAsync(html, IMG_TAG, async (tag, attrs) => {
            const src = getAttr(attrs, 'src');
            if (!src || !src.startsWith('/') || !RASTER.test(src)) return tag;

            if (!avifFor.has(src)) {
              avifFor.set(src, await makeAvif(sharp, outRoot, src, quality, logger));
            }
            const avif = avifFor.get(src);
            if (!avif) return tag;

            changed = true;
            wrapped += 1;
            return `<picture><source type="image/avif" srcset="${avif}">${tag}</picture>`;
          });

          if (changed) await writeFile(page, next, 'utf8');
        }

        const made = [...avifFor.values()].filter(Boolean).length;
        logger.info(
          `wrapped ${wrapped} image(s) in <picture> across ${pages.length} /${sectionDir} page(s), generated ${made} AVIF variant(s)`
        );
      },
    },
  };
}

async function makeAvif(sharp, outRoot, src, quality, logger) {
  const sourcePath = path.join(outRoot, src.replace(/^\//, ''));
  if (!existsSync(sourcePath)) {
    logger.warn(`skipping ${src}: not found in build output`);
    return null;
  }

  const avifPath = sourcePath.replace(/\.[^.]+$/, '.avif');
  const avifUrl = src.replace(/\.[^.]+$/, '.avif');

  try {
    await sharp(sourcePath).avif({ quality }).toFile(avifPath);
  } catch (error) {
    logger.warn(`skipping ${src}: AVIF encode failed (${error.message})`);
    return null;
  }

  const [original, encoded] = await Promise.all([stat(sourcePath), stat(avifPath)]);
  if (encoded.size >= original.size) {
    await unlink(avifPath);
    logger.info(`skipping AVIF for ${src}: no smaller than the existing file`);
    return null;
  }

  return avifUrl;
}

/** String.replace with an async replacer. */
async function replaceAsync(input, regex, replacer) {
  const jobs = [];
  input.replace(regex, (...args) => {
    jobs.push(replacer(...args));
    return '';
  });
  const results = await Promise.all(jobs);
  let i = 0;
  return input.replace(regex, () => results[i++]);
}
