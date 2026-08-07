# Authoring the learn section

Everything under `https://rlwilliamson.dev/learn` is generated from Markdown
files and one small config file. Navigation, track listings, ordering, prev and
next links, and search are all derived at build time. Nothing needs to be
registered by hand.

The short version: **adding a topic is creating one Markdown file.** If you find
yourself editing a route, an index page, or a navigation array to publish a
note, something has gone wrong and you should check this document.

- [Where things live](#where-things-live)
- [Add a topic](#add-a-topic)
- [Add a track](#add-a-track)
- [Frontmatter reference](#frontmatter-reference)
- [Images](#images)
- [Add a quiz bank](#add-a-quiz-bank)
- [Preview drafts locally](#preview-drafts-locally)
- [Search](#search)
- [What fails the build](#what-fails-the-build)

## Where things live

The Astro project is the `blog/` directory. It is named for what it originally
was; it now builds both `/blog` and `/learn` from one dependency tree and one
stylesheet.

```
blog/
  astro.config.mjs                  base '/', both sections live under src/pages
  integrations/learn-images.mjs     AVIF post-process for learn images
  src/
    config/
      site.ts                       URL prefixes: BLOG_BASE, LEARN_BASE
      tracks.ts                     display metadata for tracks
    content.config.ts               collection schemas
    content/learn/
      _template.md                  copy this to start a topic
      bicep/                        directory name is the track slug
        01-modules-and-scopes.md
        images/                     source images for this track
    data/quizzes/
      security-plus/
        fundamentals.json           question bank
    lib/
      learn.ts                      derives tracks, topics, ordering, neighbors
      quiz.ts                       loads and validates question banks
    pages/learn/
      index.astro                   /learn
      [track]/index.astro           /learn/<track>
      [track]/[slug].astro          /learn/<track>/<slug>
      [track]/practice/[set].astro  /learn/<track>/practice/<set>
  test/routes.test.mjs              route coverage against the built output
```

## Add a topic

1. Copy the template into the track directory:

   ```bash
   cp blog/src/content/learn/_template.md blog/src/content/learn/bicep/02-parameters-and-types.md
   ```

2. Fill in the frontmatter. At minimum change `title`, `description`, `track`,
   `level`, `order`, `objectives`, and `updated`.

3. Set `draft: false` when you want it published. Leave it `true` while writing;
   drafts render in `npm run dev` and are excluded from the deployed build.

4. Write the body. That is the whole process. The topic appears on `/learn`, in
   its track index, in the track sidebar, in prev and next links, and in search
   automatically.

**Filename convention.** Use `NN-slug.md`, for example `02-parameters-and-types.md`.
The `NN-` prefix keeps files in reading order in your editor and file browser.
It is stripped from the URL, so that file publishes at
`/learn/bicep/parameters-and-types`.

The prefix does **not** control ordering. The `order` field does. Keep them
consistent for your own sanity, but if they disagree, `order` wins.

## Add a track

A track is a directory under `blog/src/content/learn/`. Creating the directory
and putting one topic in it is enough. The track appears on `/learn` with a name
derived from the directory slug, for example `security-plus` becomes
`Security Plus`.

To control how it presents, add an entry to `blog/src/config/tracks.ts`:

```ts
export const TRACK_META: Record<string, TrackMeta> = {
  kubernetes: {
    name: 'Kubernetes',
    description: 'Scheduling, networking, and the failure modes that only show up under load.',
    position: 40,
  },
};
```

| Field | Effect |
| --- | --- |
| `name` | Display name in headings and navigation. Without this you get the humanized slug. |
| `description` | One line under the track name on `/learn`. Without this the space is left empty. |
| `position` | Sort order on `/learn`. Lower first. Tracks without an entry sort last, alphabetically. |

Number positions in tens so you can insert a track between two others without
renumbering.

A track directory with no published topics does not appear. That is deliberate:
an empty track is not something a reader can use. The exception is a track that
has a quiz bank but no notes yet, which appears so the practice set is reachable.

## Frontmatter reference

Every field, what it does, and whether it is required.

| Field | Type | Required | What it does |
| --- | --- | --- | --- |
| `title` | string, max 120 chars | yes | Page heading, sidebar entry, prev and next label, search result title, browser tab. |
| `description` | string, max 300 chars | yes | The line under the heading, the summary on the track index, and the page meta description. Write it as a full sentence. |
| `track` | string | yes | Must equal the directory name. It is redundant with the directory on purpose: the build fails if they disagree, which catches a file moved into the wrong folder. |
| `level` | `intro`, `working`, or `deep` | yes | Groups the topic on the track index under "Intro", "Working knowledge", or "Deep dive", and renders as a colored pill on the topic page. |
| `order` | number | yes | Position within the track. Controls the track index order, the sidebar order, and which topics are prev and next. Must be unique within a track. Number in tens. |
| `objectives` | array of strings, at least one | yes | Rendered as the "What you will be able to do" box near the top. Start each with a verb. If you cannot write two or three, the topic is not scoped tightly enough yet. |
| `prerequisites` | array of strings | no, defaults `[]` | Rendered as a "Before this" box, linked to the topics named. A bare slug resolves within the same track (`resources-and-scopes`); a qualified one crosses tracks (`bicep/resources-and-scopes`). Use the URL slug, without the `NN-` prefix. |
| `tags` | array of strings | no, defaults `[]` | Shown as pills on the topic page and the track index. Free-form; these are not their own routes the way blog tags are. |
| `updated` | date, `YYYY-MM-DD` | yes | Shown in the page header and used for the "updated" date on the track card. Bump it when you make a substantive edit. |
| `draft` | boolean | no, defaults `false` | `true` keeps the topic out of the deployed build while leaving it visible in `npm run dev`. |

## Images

Images are the only thing in this section big enough to threaten the Static Web
Apps free tier, which caps a single deployment at 250 MB. Treat the rules below
as hard requirements rather than suggestions.

**Where they go.** Source images live beside the notes, under the track:

```
blog/src/content/learn/bicep/images/deployment-scopes.png
```

Reference them with a relative path:

```markdown
![Diagram of the four Bicep deployment scopes and which resource types each allows](./images/deployment-scopes.png)
```

That is all you need. The build handles the rest:

- Astro converts the source to WebP and emits explicit `width` and `height`, so
  the page does not shift as images load.
- `loading="lazy"` and `decoding="async"` are added automatically.
- A post-build step (`blog/integrations/learn-images.mjs`) generates an AVIF
  variant with sharp and wraps the tag in a `<picture>` that offers AVIF first
  and falls back to the WebP. If an AVIF comes out no smaller than the WebP it
  is discarded, so a page never ships a larger file than it otherwise would.
- CSS caps the rendered width at the content column.

**Do not** put images in `frontend/` or reference them with a raw `<img>` tag or
an absolute path. Anything outside the pipeline ships at full size, uncompressed,
with no dimensions. The test suite fails the build if a learn page references an
image that did not come from `/_astro/`.

### Downscale before you commit

The pipeline compresses; it does not resize. A 3000 pixel wide screenshot
displayed at 700 pixels still costs you a 3000 pixel wide encode in the
repository and in the deployment.

Resize before committing:

| Image kind | Maximum width | Notes |
| --- | --- | --- |
| Screenshot, full window | 1600 px | 1200 px is usually plenty and looks identical in the content column. |
| Screenshot, cropped detail | 1000 px | Crop to the part you are actually pointing at. |
| Diagram | Prefer SVG | Vector stays sharp at any size and is usually smaller. SVG skips the raster pipeline, which is correct. |
| Photo | 1600 px | |

The content column is 736 pixels wide at its widest, so anything past about 1600
pixels is invisible even on a high density display.

```bash
# macOS, in place
sips -Z 1600 screenshot.png

# ImageMagick, only shrinks if larger
magick screenshot.png -resize '1600>' screenshot.png
```

## Add a quiz bank

Question banks are JSON under `blog/src/data/quizzes/<track>/<set>.json`. Adding
a file creates a route at `/learn/<track>/practice/<set>` and a link from the
track index. The engine is not Security+ specific; any track can use it.

```json
{
  "title": "Security+ fundamentals: a warm-up set",
  "description": "One line describing what this set covers.",
  "track": "security-plus",
  "questions": [
    {
      "id": "sp-001",
      "prompt": "The question text.",
      "domain": "General Security Concepts",
      "options": [
        { "id": "a", "text": "First option" },
        { "id": "b", "text": "Second option" },
        { "id": "c", "text": "Third option" },
        { "id": "d", "text": "Fourth option" }
      ],
      "correct": ["a"],
      "explanation": "Why the right answer is right, and why the plausible wrong ones are wrong."
    }
  ]
}
```

| Field | Rules |
| --- | --- |
| `track` | Must match the directory name. |
| `id` | Unique within the bank. Used as the HTML input name, so keep it short and free of spaces. |
| `domain` | The exam domain. This is what the per-domain score breakdown groups by, so spell it consistently across questions or you will get two buckets for one domain. |
| `options` | At least two. Each needs a unique `id` within the question. |
| `correct` | Array of option ids. One id makes it a radio question; two or more makes it checkboxes and the reader has to get the whole set right. Cannot list every option. |
| `explanation` | Required. Shown after the question is checked, or at the end in review mode. |

Behavior worth knowing when writing questions:

- Question order and option order are shuffled on every attempt, so do not write
  an option that refers to "the answer above".
- The reader picks immediate feedback or end-of-test review before starting.
- The final score breaks down per `domain`, and anything under 70 percent is
  flagged. That only helps if your domain strings are consistent.
- Nothing is stored. No accounts, no localStorage, no server. Reloading the page
  is a fresh attempt, by design.

## Preview drafts locally

```bash
cd blog
npm install
npm run dev
```

Then open `http://localhost:4321/learn`.

Drafts are visible in `npm run dev` and excluded from `npm run build`. That is
the only difference between the two, and it is why you should do a production
build before you assume something is published.

To check what will actually deploy:

```bash
cd blog
npm run build
npm run preview
```

**Search does not work in `npm run dev`.** The Pagefind index is generated from
the built output, which does not exist during development. The search box will
say so rather than failing silently. To test search, use `npm run build` then
`npm run preview`.

## Search

Pagefind indexes the static output after `astro build`, as part of
`npm run build`. It runs entirely in the browser against static index files, so
there is no backend and no API call, which is what keeps it free.

Only learn topic pages are indexed. The topic layout marks the content column
with `data-pagefind-body`, and marks the sidebar, contents, and prev and next
links `data-pagefind-ignore` so navigation text is not indexed into every page in
a track. Each topic is tagged with a `track` filter, which is how the search box
on a track index page limits results to that track.

You do not need to do anything for a new topic to be searchable.

### Why the CSP has two extra route entries

Pagefind's core is WebAssembly, which needs `'wasm-unsafe-eval'` in `script-src`.
`staticwebapp.config.json` grants that to `/learn`, `/learn/*`, **and**
`/pagefind/*`.

The third one is not redundant. Pagefind runs its index in a Web Worker, and a
dedicated worker takes its Content-Security-Policy from the response headers of
its own script, not from the page that spawned it. With only the `/learn` rules,
the document could compile WebAssembly but the worker could not, and search
failed in production while working locally. Local static servers send no CSP at
all, so this only reproduces on a real Static Web Apps deployment.

If you ever move the Pagefind output somewhere other than `/pagefind`, the route
rule has to move with it.

## What fails the build

These are deliberate. A broken note should fail the deploy, not ship.

| Problem | Message you get |
| --- | --- |
| Frontmatter `track` disagrees with the directory | names both, tells you to make them match or move the file |
| Two topics in a track share an `order` | names both files and the duplicated value |
| Two files collide after the `NN-` prefix is stripped | names both files and the URL they both want |
| A topic sits at the root of `src/content/learn` | tells you to put it in a track directory |
| A topic is nested more than one directory deep | tells you the expected layout |
| A prerequisite does not resolve to a topic | names the unresolvable reference and shows both accepted forms |
| A quiz bank does not match the schema | names the file, the field path, and what is wrong |
| A quiz bank marks an option correct that does not exist | names the question and the bad option id |
| A quiz bank sits in a directory that is not a track | names the file and the directory |
| A learn page references an image outside the pipeline | route test names the page and the bad source |
| An emoji or Unicode arrow appears in learn source | route test names the file and line |

Run the checks the way CI does:

```bash
cd blog
npm run build && npm test
```
