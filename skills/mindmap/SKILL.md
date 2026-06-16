---
name: mindmap
user-invocable: true
description: Generate an interactive Markmap mindmap from a file, pasted text, or a topic.
allowed-tools: Bash, Read, Write, Glob
---

# Mindmap Skill — Generate an Interactive Markmap

## Trigger
`/mindmap <input> [--render] [--output <path>]`

`<input>` is one of:
- a **file path** — read the file and map it
- **pasted text / notes** — map the text directly
- a short **topic** — generate a map from your own knowledge

Flags:
- `--render` — after writing the `.md`, also produce a standalone interactive `.html`
- `--output <path>` — write the `.md` to this path instead of the default

## Workflow

### Step 1: Resolve the input
Strip the flags, then classify what remains and load the content:

1. If it is the path of an **existing file**, Read it. That is the content.
2. Else if it is **long or multi-line prose** (roughly > 12 words, or contains line breaks), treat it as **raw text**. That is the content.
3. Else treat it as a **topic**: generate the content from your own knowledge.

Stop and ask the user (never silently guess) when:
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

### Step 3: Write the Markmap `.md`
Write a file in the exact shape shown under **Markmap Format** below.

Output path:
- File input `foo.md` → `foo.mindmap.md` (same directory).
- Raw-text input → slug of the map's H1 title → `<slug>.mindmap.md` in the current directory (same slug rule as topic).
- Topic input → `<topic-slug>.mindmap.md` in the current directory (slug = lowercase, spaces → `-`).
- `--output <path>` overrides the default and is written as given.
- **Before writing, use Glob to check whether the target already exists.** If it does, insert a counter before `.mindmap.md` — `<name>-2.mindmap.md`, then `<name>-3.mindmap.md`, … — and use the first name that is free. The same suffixing applies to an explicit `--output` path. **Never overwrite an existing file silently.**

After writing, tell the user the exact path and how to view it: open it at https://markmap.js.org or with the VS Code “Markmap” extension.

### Step 4 (only with `--render`): Render to HTML
`render.sh` lives in the same directory as this SKILL.md. If you don't already know that absolute path, locate it with Glob (`**/skills/mindmap/render.sh`), then run it by that path:

```
bash <skill-dir>/render.sh "<output.md>"
```

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
- The default path needs **no dependencies** (Read/Write only).
- `--render` needs Node.js / `npx` (uses `npx markmap-cli`, no global install).
