# mindmap

[English](README.md) | [中文](README.zh.md)

**Understand anything at a glance — turn a file, a URL, or a topic into a mindmap without leaving your AI coding agent.**

`mindmap` is a plugin for [Claude Code](https://docs.claude.com/en/docs/claude-code) and [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/copilot-cli). Point it at a dense report, a long article, or just a topic, and it distills the key ideas into a clean, zoomable [Markmap](https://markmap.js.org) mindmap — right from your terminal.

> Two languages in one plugin: `/mindmap` (English) and `/mindmap-zh` (中文).

---

## See it

One command turns a long GitHub blog post into a mindmap:

```
/mindmap https://github.blog/ai-and-ml/how-we-made-github-copilot-cli-more-selective-about-delegation/ --render
```

A ~1,500-word article becomes a structure you can read in seconds:

```
# Smarter Subagent Delegation
├── The Problem
│   ├── Delegation is powerful but not free
│   └── Unnecessary handoffs, overlapping searches, waiting
├── The Approach
│   ├── Analyze → find the delegation bottleneck
│   ├── Change → handle focused work directly
│   └── Validate → offline, then online, then ship
├── Results
│   ├── Tool failures per session −23%
│   └── Wait time −5% P95, no quality regression
└── What's Next
```

That's real output — see [`examples/`](examples/) for the full Markmap `.md` plus the rendered interactive `.html` (open in any browser to zoom and collapse branches).

**▶ [Open the live interactive mindmap](https://galiacheng.github.io/mindmap-skills/examples/copilot-cli-selective-delegation.mindmap.html)** — no install, just click.

---

## Why use it

- **Grasp dense material fast** — collapse a 3,000-word report into 5–7 branches you can scan at a glance, instead of reading top to bottom.
- **One command, any source** — a file, a URL, pasted notes, or just a topic. No copy-pasting into a separate web tool.
- **Stays in your workflow** — runs inside Claude Code / Copilot CLI; the map lands as a file right next to your work.
- **Smart structure, not a text dump** — mirrors a structured doc's outline, or distills loose prose into 4–7 concise branches. Nodes are short phrases, not sentences.
- **Portable, interactive output** — standard Markmap `.md` that opens anywhere, plus an optional standalone `.html` you can share.

**Good for:** skimming research papers and reports · digesting blog posts and docs · outlining a topic before you write · turning meeting notes into a shareable map.

---

## Install

The same repo is a valid plugin for **both** Claude Code and GitHub Copilot CLI — they share the plugin/marketplace format.

### Claude Code

```
/plugin marketplace add https://github.com/galiacheng/mindmap-skills.git
/plugin install mindmap@mindmap-marketplace
/reload-plugins
```

> The explicit `https://` URL avoids an SSH clone. The `galiacheng/mindmap-skills` shorthand also works **if** you have GitHub SSH keys configured; otherwise it fails with `Permission denied (publickey)`.

### GitHub Copilot CLI

```bash
copilot plugin marketplace add galiacheng/mindmap-skills
copilot plugin install mindmap@mindmap-marketplace
```

Then run `/mindmap` in your session. On Copilot CLI the skill uses the same workflow; tool names map automatically (see [`skills/mindmap/references/copilot-tools.md`](skills/mindmap/references/copilot-tools.md)).

The marketplace manifest lives at [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json).

### Manual (local, no marketplace)

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
| **URL** | `/mindmap https://example.com/article` | Fetches the page (WebFetch), maps its content. Writes `<page-slug>.mindmap.md`. |
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

This runs `npx markmap-cli <file>.md -o <file>.html --no-open` under the hood (via [`skills/mindmap/scripts/render.sh`](skills/mindmap/scripts/render.sh)).

- **The `.md` is always the guaranteed deliverable.** Rendering is best-effort.
- If `npx` / Node.js isn't installed, the skill still writes the `.md`, reports that rendering was skipped, and prints the exact command to run manually — nothing is lost.

**Requirement:** [Node.js](https://nodejs.org) (provides `npx`). No global install needed — `npx` fetches `markmap-cli` on demand.

---

## Generate mindmaps in CI (GitHub Action)

The repo ships a workflow — [`.github/workflows/generate-mindmap.yml`](.github/workflows/generate-mindmap.yml) — that runs this plugin in GitHub Actions: give it a URL, some text, or a topic, and it generates the mindmap and opens a pull request adding it to [`examples/`](examples/).

**Setup (one-time):** add a repository secret named `COPILOT_CLI_TOKEN` — a [fine-grained personal access token](https://github.com/settings/personal-access-tokens/new) with the **Copilot Requests** account permission. (The built-in `GITHUB_TOKEN` has no Copilot access, so a PAT is required.)

**Run it:** from the **Actions** tab, pick **Generate mindmap** → **Run workflow**, then fill in:

| Input | Default | Meaning |
|---|---|---|
| `input` | — | URL, pasted text, or a topic to map (required) |
| `render` | `true` | also render a standalone interactive `.html` |
| `panel` | `false` | use the multi-agent judge panel (slower, token-intensive) |
| `model` | `claude-opus-4.8` | the Copilot model to use |

**What it does:** installs [Copilot CLI](https://www.npmjs.com/package/@github/copilot), loads this repo as a plugin (`--plugin-dir`), runs the `/mindmap` skill non-interactively (`copilot -p … --model claude-opus-4.8`) to write the `.md` (and `.html`) into `examples/` and add an entry to [`examples/README.md`](examples/README.md), then commits the new files to a `mindmap/run-<id>` branch and opens a PR.

---

## How it works

This is a **prompt-driven** skill: the intelligence lives in instructions, not code.

```
skills/mindmap/
├── SKILL.md            # the workflow Claude follows: resolve input → build hierarchy → write .md → (optional) render
├── scripts/
│   └── render.sh       # the only code — a thin wrapper around `npx markmap-cli`
└── references/
    └── copilot-tools.md  # Claude Code → Copilot CLI tool-name mapping
```

- [`SKILL.md`](skills/mindmap/SKILL.md) tells Claude how to classify the input, apply the hybrid structuring rules, write a well-formed Markmap file, and handle edge cases (missing files, empty input, name collisions, render fallback).
- [`scripts/render.sh`](skills/mindmap/scripts/render.sh) is a ~35-line bash helper with deterministic exit codes (`0` ok · `1` usage · `2` file not found · `3` npx missing · `4` render failed). On success it prints only the `.html` path to stdout.

See [`docs/design-spec.md`](docs/design-spec.md) for the full design.

---

## Development

The render helper has a bash test suite (no network — it uses a fake `npx`):

```bash
bash tests/run_tests.sh
```

Expected: `ALL TESTS PASSED` (45 checks across `test_render.sh`, `test_skill_frontmatter.sh`, `test_skill_body.sh`, `test_skill_zh.sh`).

```
mindmap/
├── .claude-plugin/
│   ├── plugin.json        # plugin manifest
│   └── marketplace.json   # marketplace manifest (for /plugin marketplace add)
├── skills/
│   ├── mindmap/           # English skill (/mindmap)
│   └── mindmap-zh/        # Chinese skill (/mindmap-zh)
├── tests/                 # bash harness for render.sh + SKILL.md structure
├── examples/              # real generated output (.md + rendered .html)
├── docs/                  # design spec
├── LICENSE
└── README.md
```

---

## License

[MIT](LICENSE) © 2026 Haixia Cheng
