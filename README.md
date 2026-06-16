# mindmap

A [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin that turns **any input — a file, pasted text, or a bare topic — into an interactive [Markmap](https://markmap.js.org) mindmap.**

```
/mindmap LLM-research-report.md
/mindmap "Caching cuts latency and cost. Hit rate depends on TTL and key design. Eviction is LRU or LFU."
/mindmap "transformer attention" --render
```

The skill reads your input, builds a clean node hierarchy, and writes a Markmap `.md` file you can open as a zoomable, collapsible mindmap. Pass `--render` to also produce a standalone interactive `.html`.

---

## What it does

- **Three input types** — a file path, raw pasted text/notes, or a short topic prompt (generated from the model's own knowledge).
- **Hybrid structuring** — if your input is already structured (headings/bullets), it mirrors that outline and condenses each node to a short phrase. If it's loose prose or a topic, it extracts the key concepts into 4–7 main branches.
- **Markmap output** — a `.md` file that renders as an interactive mindmap at [markmap.js.org](https://markmap.js.org), in the VS Code [Markmap extension](https://marketplace.visualstudio.com/items?itemName=gera2ld.markmap-vscode), or as standalone HTML.
- **Optional HTML render** — `--render` shells out to `npx markmap-cli` to build a self-contained `.html`. Zero setup; if `npx` isn't available the `.md` is still produced and you get the exact manual command to run later.
- **Safe by default** — never overwrites an existing file; collisions get a `-2`, `-3`, … suffix.

---

## Install

### Option A — via marketplace (recommended)

From within Claude Code:

```
/plugin marketplace add <your-git-host>/mindmap
/plugin install mindmap@mindmap-marketplace
/reload-plugins
```

Replace `<your-git-host>/mindmap` with wherever you push this repo (e.g. `youruser/mindmap` on GitHub). The marketplace manifest lives at [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json).

### Option B — manual (local, no marketplace)

Copy the skill into your project's (or user-level) skills directory:

```bash
# project-local
mkdir -p .claude/skills
cp -r skills/mindmap .claude/skills/

# or user-level (available in every project)
mkdir -p ~/.claude/skills
cp -r skills/mindmap ~/.claude/skills/
```

Then run `/reload-skills` (or restart Claude Code). Confirm with `/help` that `/mindmap` is listed.

---

## Usage

```
/mindmap <input> [--render] [--output <path>]
```

| Input | Example | Behavior |
|---|---|---|
| **File** | `/mindmap report.md` | Reads the file, mirrors its structure, condenses nodes. Writes `report.mindmap.md`. |
| **Pasted text** | `/mindmap "notes about X, Y, Z..."` | Extracts concepts into branches. Writes `<title-slug>.mindmap.md`. |
| **Topic** | `/mindmap "vector databases"` | Generates a map from the model's knowledge. Writes `vector-databases.mindmap.md`. |

**Flags**

- `--render` — after writing the `.md`, also produce a standalone interactive `.html` (needs Node.js / `npx`).
- `--output <path>` — write the `.md` to a specific path instead of the default.

---

## Output format

The skill writes [Markmap](https://markmap.js.org)-flavored markdown — a single `#` root, `##` branches, and nested bullets:

```markdown
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

**Viewing the `.md`:**
- Paste it at [markmap.js.org](https://markmap.js.org), **or**
- Open it in VS Code with the [Markmap extension](https://marketplace.visualstudio.com/items?itemName=gera2ld.markmap-vscode), **or**
- Use `--render` to generate an `.html` you can open in any browser.

---

## Rendering to HTML

```
/mindmap "transformer attention" --render
```

This runs `npx markmap-cli <file>.md -o <file>.html --no-open` under the hood (via [`skills/mindmap/render.sh`](skills/mindmap/render.sh)).

- **The `.md` is always the guaranteed deliverable.** Rendering is best-effort.
- If `npx` / Node.js isn't installed, the skill still writes the `.md`, reports that rendering was skipped, and prints the exact command to run manually — nothing is lost.

**Requirement:** [Node.js](https://nodejs.org) (provides `npx`). No global install needed — `npx` fetches `markmap-cli` on demand.

---

## How it works

This is a **prompt-driven** skill: the intelligence lives in instructions, not code.

```
skills/mindmap/
├── SKILL.md     # the workflow Claude follows: resolve input → build hierarchy → write .md → (optional) render
└── render.sh    # the only code — a thin wrapper around `npx markmap-cli`
```

- [`SKILL.md`](skills/mindmap/SKILL.md) tells Claude how to classify the input, apply the hybrid structuring rules, write a well-formed Markmap file, and handle edge cases (missing files, empty input, name collisions, render fallback).
- [`render.sh`](skills/mindmap/render.sh) is a ~35-line bash helper with deterministic exit codes (`0` ok · `1` usage · `2` file not found · `3` npx missing · `4` render failed). On success it prints only the `.html` path to stdout.

See [`docs/design-spec.md`](docs/design-spec.md) for the full design and [`docs/implementation-plan.md`](docs/implementation-plan.md) for the build.

---

## Development

The render helper has a bash test suite (no network — it uses a fake `npx`):

```bash
bash tests/run_tests.sh
```

Expected: `ALL TESTS PASSED` (25 checks across `test_render.sh`, `test_skill_frontmatter.sh`, `test_skill_body.sh`).

```
mindmap/
├── .claude-plugin/
│   ├── plugin.json        # plugin manifest
│   └── marketplace.json   # marketplace manifest (for /plugin marketplace add)
├── skills/mindmap/
│   ├── SKILL.md
│   └── render.sh
├── tests/                 # bash harness for render.sh + SKILL.md structure
├── docs/                  # design spec + implementation plan
├── LICENSE
└── README.md
```

---

## License

[MIT](LICENSE) © 2026 Haixia Cheng
