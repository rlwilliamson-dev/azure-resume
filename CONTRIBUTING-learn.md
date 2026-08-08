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
- [Certification tracks](#certification-tracks)
- [Capturing command output](#capturing-command-output)
- [Images](#images)
- [Add a quiz bank](#add-a-quiz-bank)
- [Preview drafts locally](#preview-drafts-locally)
- [Search](#search)
- [Check citation links](#check-citation-links)
- [What fails the build](#what-fails-the-build)

## Where things live

The Astro project is the `blog/` directory. It is named for what it originally
was; it now builds both `/blog` and `/learn` from one dependency tree and one
stylesheet.

```
blog/
  astro.config.mjs                  base '/', both sections live under src/pages
  integrations/learn-images.mjs     AVIF post-process for learn images
  scripts/
    distros.json                    container images pinned for output capture
    capture.sh                      run a command in a distro, emit a code block
    check-links.mjs                 fetch every URL in every `sources` array
  src/
    config/
      site.ts                       URL prefixes: BLOG_BASE, LEARN_BASE
      tracks.ts                     display metadata for tracks
      exams.ts                      canonical exam domains and objectives
    content.config.ts               collection schemas
    content/learn/
      _template.md                  copy this to start a topic
      _template-certification.md    copy this for an exam-backed track
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
      [track]/coverage.astro        /learn/<track>/coverage, certification tracks only
      [track]/plan.astro            /learn/<track>/plan, certification tracks only
      [track]/practice/[set].astro  /learn/<track>/practice/<set>
  test/routes.test.mjs              route coverage against the built output
```

## Add a topic

1. Copy the template into the track directory. There are two:

   ```bash
   cp blog/src/content/learn/_template.md blog/src/content/learn/bicep/02-parameters-and-types.md
   ```

   ```bash
   cp blog/src/content/learn/_template-certification.md blog/src/content/learn/linux-plus/02-the-boot-process.md
   ```

   `_template.md` is the general one. `_template-certification.md` is for a
   track with an exam behind it: it carries the `examObjectives`, `sources`, and
   `symptoms` frontmatter, and the fixed section order every topic in a
   certification track uses. **Use it as-is rather than reordering sections.**
   Forty topics that each answer the same questions in the same order is the
   point; a reader who has read three of them knows where to look in the fourth.

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

### Section numbers are automatic

**Never number a heading by hand.** The `##` sections on a topic page are
numbered by a CSS counter, and `TableOfContents.astro` reproduces the same
sequence for the contents panel. Reordering, inserting, or deleting a section
renumbers everything with no edit.

The topic page also shows `Topic N of M` in its header, and the sidebar numbers
every topic in reading order. Both come from the topic's position in the track,
so inserting a topic renumbers the rest on its own. This is what stops a
forty-topic track feeling like an unordered pile.

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
| `examObjectives` | array of objects | no, defaults `[]` | Certification objectives this topic covers. Each entry needs `exam` (a slug from `src/config/exams.ts`, for example `xk0-006`), `domain` (`"1.0"`), and `objective` (`"1.3"`). Renders the "On the exam" block at the top of the topic and drives the coverage report. Validated against the canonical exam definition, so a typo fails the build rather than becoming a silent gap. |
| `sources` | array of objects | no, defaults `[]` | Citations backing the claims in this topic. Each entry needs `title`, `url`, `publisher`, `accessed` (`YYYY-MM-DD`), and `tier` (`1` for primary, `2` for high-quality secondary). **Required if `examObjectives` is non-empty.** |
| `symptoms` | array of objects | no, defaults `[]` | Observable symptoms this topic explains, for the planned symptom index. Each entry needs `symptom` and may have `anchor`, a heading anchor in this topic without the leading `#`. Nothing renders this yet; populating it now avoids a migration later. |

## Certification tracks

A track becomes a certification track by getting an entry in
`EXAM_FOR_TRACK` in `blog/src/config/exams.ts`. That one line turns on two
routes and lets topics claim objectives:

| Route | What it does |
| --- | --- |
| `/learn/<track>/coverage` | Every objective, which topics cover it, how many questions target it, and which domains are under their weighted share |
| `/learn/<track>/plan` | A spaced study plan: topics distributed across weeks, each week's reading returning the following week, ending in mixed practice and full exams |

Both are generated from the topics that exist, so they reflow as topics are
added. The plan reports the number of weeks it actually lays out rather than a
target it has not reached.

`exams.ts` is the only place objective numbers are written down. The coverage
page renders from it and frontmatter is validated against it, so nothing else in
the codebase should hardcode an objective number.

A topic that claims an objective renders an **On the exam** block above its
prerequisites, showing the objective number, the vendor's own objective
statement, the domain it belongs to, and what that domain is worth as a
percentage of the exam. It is generated from `exams.ts`, so a reader always sees
why a topic is on the site and how much it counts for, and nothing about it is
maintained by hand.

Two rules apply to any topic that claims an objective:

1. **The objective has to exist**, and the `domain` has to be the one that
   objective actually belongs to. Both are checked at build time.
2. **The topic has to cite.** A topic making factual claims about command
   behavior, default values, and file paths needs sources somebody can check.
   The rule is scoped to topics with `examObjectives`, so notes written before it
   existed are not retroactively broken.

Objective numbers and titles are reproduced because they are how an exam is
referenced. Vendor objectives documents are copyrighted; do not paste their
bulleted sub-lists into a topic or into `exams.ts`.

## Capturing command output

Terminal output in a certification topic is either **captured** or **sourced from
documentation**, and the topic says which. Nothing gets typed into a code fence
from memory.

`blog/scripts/capture.sh` runs a command in a pinned container and prints a block
ready to paste:

```bash
cd blog/scripts
./capture.sh debian -- 'dpkg -S /usr/bin/ls'
```

```bash
./capture.sh alma --arch arm64 -- 'uname -m'
```

Distro keys are `alma`, `debian`, `ubuntu`, and `suse`; images are pinned by
digest per architecture in `distros.json`. Captures default to x86_64, because
that is the context these exams assume and because architecture leaks into
output.

### `--script`, and why it is fast

Most captures need a package the base image does not have. That goes in a setup
script, so the install noise stays out of the transcript:

```bash
./capture.sh debian --script setup/tls.sh -- 'openssl x509 -in ca.crt -noout -dates'
```

**The setup runs once and is then cached as a local image.** The cache key is the
base image digest, the architecture, and the contents of the setup script, so
editing the script rebuilds and nothing goes stale. In practice this is the
difference between a capture taking 40 seconds and taking 1 second, which matters
because a topic needs a dozen of them and the alternative is reinstalling the same
three packages a dozen times.

Two things to know when writing one:

- **`cd` carries over.** The build records the working directory the script ended
  in and the run restores it.
- **`export` does not.** Environment variables set in setup are gone by the time
  the captured command runs. Put them in the command if they matter, which is
  usually what you want anyway since the transcript should show them.

- **A background process does not survive.** A commit preserves the filesystem,
  not running processes, so a setup that starts a daemon — `openssl s_server`, a
  `slapd`, an `rsyslogd` — needs `--no-cache`. The symptom is an empty capture:
  the command ran, and the thing it was talking to was not there.

**The captured command runs under `/bin/sh`, which is dash on Debian and Ubuntu.**
Bash-only syntax — `for ((i=0;;))`, `[[ ]]`, `read -d`, arrays — fails with
`Syntax error: Bad for loop variable` or `read: Illegal option -d`. Put the
demonstration in a script with a `#!/bin/bash` shebang and capture `cat script.sh`
followed by running it, which reads better anyway and is what a reader would do.

`--no-cache` skips all of this and runs setup inline, which is what you want for
the daemon case above, or if a setup step must genuinely happen fresh every time.
`--block` captures always run inline, because a container built against one set of
loop devices is no use against another.

The images accumulate under `localhost/capture-setup`. `podman image prune -a`
clears them and the next capture rebuilds what it needs.

### The `vm` target, for anything needing a kernel

A container borrows the host's kernel and has none of its own, so nothing about
booting, kernel modules, firmware, hardware, or network configuration can be
captured in one. The `vm` key runs the command on the podman machine itself:

```bash
./capture.sh vm -- 'lsmod | head'
./capture.sh vm -- 'sudo efibootmgr | head -8'
```

Write `sudo` into the command yourself where it is needed, so the transcript
shows what a reader would actually type. `--arch` is rejected, because the
machine's architecture is not a choice.

**Say what the machine is.** It is a virtual machine running Fedora CoreOS, on
the host's architecture. `lspci` reports virtio devices, `lscpu` reports the host
CPU, and `dmidecode` names the hypervisor. That is an accurate picture of a cloud
instance and a poor one of a server in a rack, and the prose has to be the one to
say so. It is also an image-based system, so its mount layout is unusual; prefer
a container capture where that would confuse more than it teaches.

### Block devices, LVM, and RAID

`--block N` provisions N real loop devices and runs the container privileged
against them, so LVM, `mdadm`, `mkfs`, `fsck`, and `mount` produce genuine
output:

```bash
./capture.sh alma --block 2 -- 'pvcreate $DEVS && vgcreate vgdata $DEVS && vgs'
```

The device paths arrive as `$DEVS` (space-separated) and `$DEV0`, `$DEV1`, and
so on. **Never hardcode `/dev/loop0`**: the podman machine uses low-numbered
loop devices for its own storage, so yours will not start at zero.

`--block` works with the `vm` target too, and that combination is the one to use
whenever a **partition** has to appear:

```bash
./capture.sh vm --block 1 -- 'sudo sgdisk -n 1:0:0 -t 1:8300 $DEV0; sudo lsblk $DEV0'
```

Loop devices are attached with `losetup -P`, so the kernel creates
`/dev/loopNpM` as partitions are written. Those nodes reach the `vm` target
because it runs on the machine that owns them. They do **not** reach a container,
which only receives the devices that existed when it started — so a container can
partition a disk and then cannot use the result. Whole-device work (LVM members,
RAID members, `mkfs` on a bare disk) is fine either way.

`--block-size` changes the default 512M when a topic needs more room.

The container form routes through the podman machine VM as root, because
device-mapper is not reachable from a rootless container. Two consequences:

- It runs on the VM's architecture, so the label says `aarch64` on Apple
  Silicon. Block-layer output does not vary by architecture, but the label is
  honest about where it came from. `--arch` is rejected with `--block` rather
  than silently ignored.
- LVM needs `--config "activation{udev_sync=0 udev_rules=0}"` inside a
  container, because there is no udev to wait for. Without it `lvcreate` fails
  with `not found: device not cleared`.

The script resets device-mapper and detaches its loop devices before and after
every run, so captures are repeatable. Removing a loop device does not remove
the dm node built on top of it, and an orphan makes the next run report
`volume group already exists` against a device that was just wiped.

### Hide the important output behind a prediction

Reading output is the most passive moment on a page, and a page that reads well
is exactly what produces confidence that does not survive an exam. Two or three
times per topic, make the reader commit before they look:

```markdown
<details class="predict">
<summary>A specific question about what this prints, and why.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ command
output
```

</details>
```

**The blank lines around the fence are required.** Without them the code block
is inside an HTML block and never gets parsed as Markdown, so it ships as plain
text with no highlighting.

Plain `<details>`, so it needs no JavaScript and is keyboard operable. Use it on
the blocks that carry the teaching; on all of them it becomes furniture.

### The three collapsible patterns

All plain `<details>`, so none of them need JavaScript and all are keyboard
operable. Blank lines around any Markdown inside are required, or it ships as
plain text.

| Class | For | Rule |
| --- | --- | --- |
| `predict` | Hiding command output behind a question | Two or three per topic. **The reader must be able to answer from what they have just read.** State the rule, then ask them to apply it. |
| `deeper` | Depth for experienced administrators | **Three or four per topic**, each placed immediately after the section it extends. A topic with none is pitched too high for a beginner; a topic with one long one at the foot of the page has buried it. |
| `qa` | Check-yourself answers | One per question. The answer explains why, names the tempting wrong answer, and adds the thing they will need next. |

Certification topics also open with a `terms` definition list where new
vocabulary appears, because expert blind spot is mostly a vocabulary problem.

**Placing `deeper` panels.** After each substantial section, ask whether an
administrator with five years of experience would have a follow-up question
about *that section*. If so, that is a panel, and it belongs there rather than
in a collected appendix. The pairing is the point: somebody who wants the LVM
snapshot caveat should meet it beside the LVM section, not five screens later
inside a wall of prose covering four other subjects.

Good panels carry operational consequence — the failure mode, the flag that
avoids it, the number a vendor will ask for. More vocabulary is not depth.

### What still cannot be captured

- **Real hardware.** `lspci`, `lsusb`, and `dmidecode` report the hypervisor's
  virtio devices, not server hardware. The `vm` target makes the output real; it
  does not make the hardware real.
- **Boot and recovery as they happen.** The `vm` target gives you the *evidence*
  of a boot — `systemd-analyze`, `/proc/cmdline`, `efibootmgr`, the UEFI
  partition layout — but not a GRUB menu, a failed boot, or a rescue shell.
- **A second machine.** Anything about reaching another host, serving a port to
  it, or a client-server protocol between two systems.
- **Live firewall state** against a real netfilter, and anything graphical.

Output for those comes from man pages and vendor documentation instead. Such a
block carries no distro-and-architecture comment line, and the surrounding prose
says which distribution it applies to. That absence is the signal: **a block
with a `# Distro, arch` header was captured; a block without one was sourced.**

Requires `podman`: `brew install podman && podman machine start`.

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
| `objective` | Optional. The objective number this question targets, for example `"1.3"`. The coverage report counts questions per objective from this, so a question without one is invisible there. |
| `scenario` | Optional. A preamble putting the system in a described state, for scenario-style items. Renders above the prompt so the prompt itself stays short. |
| `learnRef` | Optional. The topic that explains this question, resolved like `prerequisites`: a bare slug stays in the track, a qualified one crosses tracks. This is what turns a wrong answer into a link back to the material. |
| `learnAnchor` | Optional. A heading anchor inside that topic, without the leading `#`. Validated against the rendered headings, so a reorganised topic fails the build instead of shipping a dead link. |
| `difficulty` | Optional. `recall`, `application`, or `analysis`. The build warns when a certification bank is more than half `recall`. |

**On a certification track**, `objective`, `learnRef`, and `difficulty` are
required on every question. They are optional in the schema so the Security+
banks keep validating, and mandatory by a track-scoped rule in
`src/lib/quiz-validate.ts`.

Before writing questions, read
[docs/linux-plus-question-authoring-standard.md](docs/linux-plus-question-authoring-standard.md).
It covers what CompTIA prohibits, what it permits, and the item-writing rules
these banks follow. The short version: write from the published objectives and
primary documentation, never from a braindump and never from memory of a real
exam, and make every distractor a mistake somebody has actually made.
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

## Check citation links

Citations rot. A topic pointing at a vendor page that has since moved is worse
than one citing nothing, because it looks checked.

```bash
cd blog
npm run check:links
```

```bash
npm run check:links -- --track linux-plus
```

It fetches every URL in every `sources` array, follows redirects, retries a HEAD
failure with a GET, and exits non-zero listing the file that owns each broken
link.

**This is deliberately not part of `npm run build`.** Those URLs point at other
people's servers, and somebody else's outage must never block a deploy. It runs
weekly in its own GitHub Actions workflow (`.github/workflows/check-links.yml`),
which can also be triggered by hand for a single track. A failing scheduled run
emails the repository owner; that is the whole notification mechanism.

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
| An `examObjectives` entry names an exam that is not defined | names the file and lists the known exam slugs |
| An `examObjectives` entry names an objective the exam does not have | names the file and the bad objective number |
| An `examObjectives` entry puts an objective in the wrong domain | names the file and the domain that objective actually belongs to |
| A topic lists the same objective twice | names the file and the objective |
| A topic claims exam coverage with no `sources` | names the file and the objectives it claims |
| Domain weights for an exam do not total 100 | names the exam and the total it came to |
| A quiz bank does not match the schema | names the file, the field path, and what is wrong |
| A quiz bank marks an option correct that does not exist | names the question and the bad option id |
| A quiz bank is not at `src/data/quizzes/<track>/<set>.json` | names the file and the expected layout |
| A quiz bank's `track` disagrees with its directory | names both and tells you to move the file |
| A quiz bank sits in a directory that is neither a content track nor in `tracks.ts` | names the file and the directory, and tells you to check the name |
| An option is "all of the above" or "none of the above" | names the question and points at the item-writing rule |
| Any field claims to reproduce real exam content | names the question, the field, and the phrase |
| Two questions in a track share an `id` | names both files, because results aggregate across banks |
| A certification question is missing `objective`, `learnRef`, or `difficulty` | names the question and the missing fields |
| A question targets an objective the exam does not have | names the question and the bad objective |
| A question's `domain` disagrees with its objective's domain | names both, because domain strings drive the score breakdown |
| A `learnRef` does not resolve to a topic | names the reference and shows both accepted forms |
| A `learnAnchor` does not match a heading in that topic | names the anchor and lists headings that do exist |
| A `learnAnchor` is set without a `learnRef` | says an anchor needs a topic to be an anchor in |

And the warnings, which print during the build without failing it: a bank
weighted toward `recall`, a correct option much longer than its distractors, a
negative stem, an explanation that never addresses a wrong option, a domain
below its weighted share, and objectives with no questions at all.
| A learn page references an image outside the pipeline | route test names the page and the bad source |
| An emoji or Unicode arrow appears in learn source | route test names the file and line |

The last one is worth understanding precisely, because it has two halves. A bank
in a directory with **no topics but an entry in `tracks.ts`** is fine: it creates
a track, so a practice set can ship before the notes are written. That is
deliberate, and it is why `security-plus` appears on `/learn` with a bank and no
topics. A bank in a directory with **neither** topics nor a `tracks.ts` entry is
a typo, and the build says so. The check lives in the practice route's
`getStaticPaths`, not in `lib/quiz.ts`.

Run the checks the way CI does:

```bash
cd blog
npm run build && npm test
```
