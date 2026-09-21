---
name: mindmap
user-invocable: true
description: Generate an interactive Markmap mindmap from a file, a URL, pasted text, or a topic.
---

# Mindmap Skill — Generate an Interactive Markmap

## Trigger
`/mindmap <input> [--panel] [--render] [--output <path>]`

This is slash-command notation, not a required host API. If the host does not expose slash commands, invoke the `mindmap` skill using its supported mechanism with the same input and options.

`<input>` is one of:
- a **file path** — read the file and map it
- a **URL** (`http://` or `https://`) — fetch the page and map its content
- **pasted text / notes** — map the text directly
- a short **topic** — generate a map from your own knowledge

Flags:
- `--panel` — design the structure with a multi-agent judge panel (token-intensive; best for complex/important sources like papers). See **Step 2 → Judge Panel**.
- `--render` — after writing the `.md`, also produce a standalone interactive `.html`
- `--output <path>` — write the `.md` to this path instead of the default

## Agent capabilities

Use the tools available in the current session for each capability below; no particular tool names are required. Follow the host's permissions and approval rules. Installing this skill does not grant additional permissions.

| Operation | Required capability |
|---|---|
| Basic `.md` output | Inspect paths and create files; file input also requires reading files. |
| URL input | Retrieve the page's main content using an available web-fetch capability. |
| `--render` | Execute commands, with Bash and Node.js / `npx` available for the supplied helper. |
| `--panel` | Delegate to independent subagents and collect their results. |

If you cannot inspect or write files, explain the missing capability or permission and ask the user how to proceed; do not claim a file was saved. Handle unavailable web access, rendering, and subagents as described in the relevant steps below.

## Workflow

### Step 1: Resolve the input
Strip the flags, then classify what remains and load the content:

1. If it is a **URL** (starts with `http://` or `https://`), use the available web-fetch capability to retrieve the page's main text content. The fetched content is the content. Check this **first**, before the file/text/topic rules.
2. Else if it is the path of an **existing file**, read it using the available file-reading capability. That is the content.
3. Else if it is **long or multi-line prose** (roughly > 12 words, or contains line breaks), treat it as **raw text**. That is the content.
4. Else treat it as a **topic**: generate the content from your own knowledge.

Stop and ask the user (never silently guess) when:
- **Web access is unavailable or a URL fetch fails** (network error, blocked, or empty page) → report it and ask the user to paste the content, retry when access is available, or explicitly choose a topic-based map. Do not invent page content.
- It **looks like a file path** (ends in `.md`/`.txt`, or contains `/` or `\`) but the file **does not exist** → report `no file at <path>` and ask: map it as a topic instead, or fix the path?
- It is **empty or whitespace only** → ask for content or a topic.
- It is genuinely **ambiguous** (a short phrase that could be raw text or a topic) → default to **topic generation** and say so in one line so the user can correct you.

### Step 2: Build the structure (hybrid)
Turn the content into a node hierarchy:

- If the content is **already structured** (clear headings / a bullet outline): follow that outline, but **condense each node to a short phrase** (≤ ~8 words). Do not copy sentences verbatim.
- If the content is **unstructured** prose or a **topic**: extract the key concepts and group them into **4–7 main branches**, each with concise sub-points.

Rules:
- **Depth:** aim for 3–4 levels.
- **Phrases, not sentences:** every node is a short label.
- **Legibility over completeness:** for a very large source, map its structure and key points — not every line. Target **4–7 main branches** for unstructured/topic/large sources; when the source is already structured, mirror its own outline instead. Condense aggressively.

#### Judge Panel (only with `--panel`)
When `--panel` is passed, do not build the structure single-handed. Instead run a
multi-agent panel using the host's available subagent capabilities and the prompts in
[`references/judge-panel.md`](references/judge-panel.md):

If there is no independent subagent capability or delegation is not permitted,
explain that `--panel` is unavailable and ask whether to continue without
`--panel`. Do not simulate independent agents in one context or silently downgrade.

1. **Propose** — 3 proposer agents each design a full structure through a
   different lens (narrative-first, data-first, audience-first), assigning every
   node a **format** (list/table/code/checkbox/link/bold) and a **tier**
   (`core` renders everywhere; `rich` = table/code/checkbox, standard-markmap only).
2. **Judge** — 3 judge agents independently score all proposals on the rubric
   (skill rules + presentation: punchline-first, headline numbers, leaf
   legibility, visual balance, format fit) and name each proposal's best idea.
3. **Synthesize** — 1 synthesizer agent takes the top-scored proposal as the
   spine, grafts the judges' flagged ideas, and emits the final Markmap `.md`.

Use the execution protocol and the exact prompts/output shapes in the reference file.
Subagents may run in parallel or sequentially; preserve the propose, judge, and
synthesize stages. No particular orchestration API is required.
Cost note: this spawns ~7 agents and is token-intensive — reserve it for complex
or high-stakes sources. If all proposers fail, fall back to the normal Step 2
single-pass build and tell the user.

**Render-tier safety:** the synthesizer keeps `rich` formats — they render on the
default `.md` path (markmap.js.org / VS Code ext / `--render`). The vertical
**poster** path (`scripts/parse-md.mjs`) reads only `##` headings and `-`
bullets, so before sending a panel `.md` down the poster path, pass it through
`scripts/degrade-rich.mjs` (`node scripts/degrade-rich.mjs <in.md> <out.md>`),
which rewrites tables/code/checkboxes as bullets. Content is reshaped, **never
silently dropped**.

### Step 3: Write the Markmap `.md`
Write a file in the exact shape shown under **Markmap Format** below.

Output path:
- File input `foo.md` → `foo.mindmap.md` (same directory).
- URL input → slug of the page title (or the URL's last path segment) → `<slug>.mindmap.md` in the current directory.
- Raw-text input → slug of the map's H1 title → `<slug>.mindmap.md` in the current directory (same slug rule as topic).
- Topic input → `<topic-slug>.mindmap.md` in the current directory (slug = lowercase, spaces → `-`).
- `--output <path>` overrides the default and is written as given.
- **Before writing, use the available filesystem inspection capability to check whether the target already exists.** If it does, insert a counter before `.mindmap.md` — `<name>-2.mindmap.md`, then `<name>-3.mindmap.md`, … — and use the first name that is free. The same suffixing applies to an explicit `--output` path. **Never overwrite an existing file silently.**

After writing, tell the user the exact path and how to view it: open it at https://markmap.js.org or with the VS Code “Markmap” extension.

### Step 4 (only with `--render`): Render to HTML
`render.sh` lives in the `scripts/` folder next to this installed SKILL.md. Resolve that location using the host's skill metadata or available file-search capability, then use its command-execution capability to run the helper by its absolute path:

```
bash "<skill-dir>/scripts/render.sh" "<output.md>"
```

- If you cannot execute commands, cannot locate the helper, or Bash / Node.js / `npx` is unavailable, preserve the `.md` and clearly explain why HTML was not rendered. Provide the manual command `npx --yes markmap-cli "<output.md>" -o "<output.html>" --no-open`, using the actual output paths, for an environment with Node.js. Do not claim an HTML file exists.
- On success it prints the `.html` path on stdout — report it to the user.
- If it exits non-zero (e.g. `npx` not available, exit code 3), the `.md` is still the guaranteed deliverable. Tell the user rendering was skipped, and show any manual command it printed (the exit-3 npx-missing case prints one). Do **not** treat this as a failure of the whole task.

## Markmap Format
Write the `.md` like this:

```
---
title: <map title>
markmap:
  colorFreezeLevel: 2
  maxWidth: 300
---

# <Central topic>

## <Branch 1>
- <point>
  - <sub-point>
- <point>

## <Branch 2>
- <point>
```

- Exactly **one `#` H1** — the root / central topic.
- `##` H2 = main branches; `###` and `-` bullets = deeper levels.
- Inline markdown (`**bold**`, `` `code` ``, links) is allowed and passes through.
- Keep the frontmatter defaults (`colorFreezeLevel: 2`, `maxWidth: 300`) as-is.

## Worked Example
Input (a structured snippet):

> # Retrieval-Augmented Generation
> ## Indexing
> Chunk documents, embed them, store the vectors.
> ## Retrieval
> Embed the query, find the nearest chunks.
> ## Generation
> Inject the retrieved context into the prompt.

Output `retrieval-augmented-generation.mindmap.md`:

```
---
title: Retrieval-Augmented Generation
markmap:
  colorFreezeLevel: 2
  maxWidth: 300
---

# Retrieval-Augmented Generation

## Indexing
- Chunk documents
- Embed chunks
- Store vectors

## Retrieval
- Embed the query
- Find nearest chunks

## Generation
- Inject context into prompt
```

## Notes
- The default path needs **no additional runtime dependencies**, only filesystem capabilities; URL input also needs web access.
- Automated `--render` needs command execution, Bash, and Node.js / `npx` (uses `npx markmap-cli`, no global install).
