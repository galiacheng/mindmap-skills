# Mindmap Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a user-invocable `/mindmap` Claude Code skill that turns a file, pasted text, or a topic into an interactive [Markmap](https://markmap.js.org) `.md`, with an optional `--render` step that produces standalone HTML.

**Architecture:** Prompt-driven skill (Approach A). The reading/structuring logic lives as instructions in `SKILL.md`; the only code is a thin `render.sh` that wraps `npx markmap-cli`. Layout mirrors the repo's existing `deep-research-skills/skills/<name>/` package convention. Bash test scripts give the code real red→green TDD; structural tests validate the `SKILL.md` so a malformed skill can't ship.

**Tech Stack:** Bash (skill + tests), Markdown/YAML (SKILL.md, Markmap output), Node.js/`npx markmap-cli` (render only — already present: Node v22, npx on PATH).

---

## Pre-flight Notes (read once)

- **Working directory:** `C:/Users/haiche/Documents/HelloWord` (run all commands from here unless a step says otherwise).
- **Git is optional.** This folder is **not** a git repo and the user chose to skip git for now. Task 1 Step 1 runs `git init` so the `Commit` steps work and you get checkpoints. **If you prefer no git, skip every `git` step** — the deliverables are byte-identical either way.
- **Two locations for the skill:**
  - **Canonical source** (portable/publishable, matches the spec): `mindmap-skill/skills/mindmap/`
  - **Install target** (where Claude Code discovers project skills): `.claude/skills/mindmap/` — populated by a copy in Task 7.
- **Tests live with the package:** `mindmap-skill/tests/`. Run them with `bash mindmap-skill/tests/run_tests.sh`.

---

## File Structure

```
mindmap-skill/
├── skills/
│   └── mindmap/
│       ├── SKILL.md          # instructions + format spec + worked example (prose)
│       └── render.sh         # npx markmap-cli wrapper for --render (the only code)
└── tests/
    ├── lib.sh                # minimal bash assert helpers
    ├── run_tests.sh          # runs every test_*.sh, aggregates pass/fail
    ├── fixtures/
    │   └── sample.mindmap.md # tiny valid markmap used by render tests
    ├── test_render.sh        # behavior tests for render.sh
    ├── test_skill_frontmatter.sh   # SKILL.md frontmatter validation
    └── test_skill_body.sh          # SKILL.md required-sections validation
```

Install copy (Task 7): `.claude/skills/mindmap/{SKILL.md,render.sh}`.

Responsibilities:
- `render.sh` — one job: given a `.md`, produce an `.html` via `npx markmap-cli`, with deterministic exit codes and graceful degradation when `npx` is absent.
- `SKILL.md` — one job: instruct Claude how to resolve input, build the hybrid structure, write the Markmap `.md`, and (optionally) call `render.sh`.
- `lib.sh` / `run_tests.sh` — the test harness, shared by all test files.

---

## Task 1: Scaffold package, test harness, and fixture

**Files:**
- Create: `mindmap-skill/tests/lib.sh`
- Create: `mindmap-skill/tests/run_tests.sh`
- Create: `mindmap-skill/tests/fixtures/sample.mindmap.md`
- Create: `mindmap-skill/skills/mindmap/` (directory)

- [ ] **Step 1: Initialize git (optional) and create directories**

Run:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null || git init
mkdir -p mindmap-skill/skills/mindmap mindmap-skill/tests/fixtures
```
Expected: `git init` prints `Initialized empty Git repository...` (or the repo already exists), and the directories are created. (Skip the `git` part if you are not using git.)

- [ ] **Step 2: Write the test helper library**

Create `mindmap-skill/tests/lib.sh`:
```bash
# lib.sh — minimal bash test helpers. Source this from each test_*.sh.
# Usage: source lib.sh; assert_eq "$expected" "$actual" "label"; ...; finish
_tests_run=0
_tests_failed=0

assert_eq() { # expected actual label
  _tests_run=$((_tests_run + 1))
  if [ "$1" = "$2" ]; then
    echo "  ok: $3"
  else
    _tests_failed=$((_tests_failed + 1))
    echo "  FAIL: $3 (expected '$1', got '$2')" >&2
  fi
}

assert_contains() { # haystack needle label
  _tests_run=$((_tests_run + 1))
  case "$1" in
    *"$2"*) echo "  ok: $3" ;;
    *) _tests_failed=$((_tests_failed + 1)); echo "  FAIL: $3 (missing '$2')" >&2 ;;
  esac
}

finish() { # returns non-zero if any assertion failed
  echo "  ($_tests_run checks, $_tests_failed failed)"
  [ "$_tests_failed" -eq 0 ]
}
```

- [ ] **Step 3: Write the test runner**

Create `mindmap-skill/tests/run_tests.sh`:
```bash
#!/usr/bin/env bash
# Run every test_*.sh in this directory. Exit non-zero if any test fails.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
shopt -s nullglob
tests=("$here"/test_*.sh)
if [ "${#tests[@]}" -eq 0 ]; then
  echo "no test files yet"
  exit 0
fi
fail=0
for t in "${tests[@]}"; do
  echo "== $(basename "$t") =="
  bash "$t" || fail=1
done
if [ "$fail" -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "SOME TESTS FAILED"; fi
exit "$fail"
```

- [ ] **Step 4: Write the render-test fixture**

Create `mindmap-skill/tests/fixtures/sample.mindmap.md`:
```text
---
title: Sample
markmap:
  colorFreezeLevel: 2
  maxWidth: 300
---

# Sample

## Branch A
- point 1
- point 2

## Branch B
- point 3
```

- [ ] **Step 5: Run the harness to verify it executes cleanly**

Run: `bash mindmap-skill/tests/run_tests.sh`
Expected: prints `no test files yet` and exits 0.

- [ ] **Step 6: Commit**

```bash
git add mindmap-skill/tests/lib.sh mindmap-skill/tests/run_tests.sh mindmap-skill/tests/fixtures/sample.mindmap.md
git commit -m "chore: scaffold mindmap skill package and test harness"
```

---

## Task 2: `render.sh` — argument validation

The renderer's first two exit codes: `1` usage error (no `.md` arg), `2` markmap file not found.

**Files:**
- Create: `mindmap-skill/skills/mindmap/render.sh`
- Test: `mindmap-skill/tests/test_render.sh`

- [ ] **Step 1: Write the failing test**

Create `mindmap-skill/tests/test_render.sh`:
```bash
#!/usr/bin/env bash
# Tests for render.sh. Run: bash test_render.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/lib.sh"
RENDER="$here/../skills/mindmap/render.sh"
FIXTURE="$here/fixtures/sample.mindmap.md"

# Case 1: no argument -> usage error, exit 1
bash "$RENDER" >/dev/null 2>&1; rc=$?
assert_eq 1 "$rc" "no arg exits 1 (usage)"

# Case 2: missing .md file -> exit 2
bash "$RENDER" "$here/fixtures/does-not-exist.md" >/dev/null 2>&1; rc=$?
assert_eq 2 "$rc" "missing md exits 2"

finish
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash mindmap-skill/tests/test_render.sh`
Expected: FAIL — `render.sh` does not exist yet, so both cases report wrong exit codes (e.g. `127`).

- [ ] **Step 3: Write the minimal implementation**

Create `mindmap-skill/skills/mindmap/render.sh`:
```bash
#!/usr/bin/env bash
# render.sh — render a Markmap .md to standalone interactive HTML.
# Usage: render.sh <md-path> [html-path]
# Exit codes: 0 ok | 1 usage | 2 md not found | 3 npx missing | 4 render failed
set -euo pipefail

md="${1:-}"
if [ -z "$md" ]; then
  echo "usage: render.sh <md-path> [html-path]" >&2
  exit 1
fi

if [ ! -f "$md" ]; then
  echo "error: markmap file not found: $md" >&2
  exit 2
fi
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash mindmap-skill/tests/test_render.sh`
Expected: PASS — both checks ok, `(2 checks, 0 failed)`.

- [ ] **Step 5: Commit**

```bash
git add mindmap-skill/skills/mindmap/render.sh mindmap-skill/tests/test_render.sh
git commit -m "feat: render.sh argument validation (usage + missing file)"
```

---

## Task 3: `render.sh` — graceful degradation when `npx` is missing

When `npx` is absent the `.md` is still safe; the renderer must exit `3` with a copy-pasteable manual command, not crash.

**Files:**
- Modify: `mindmap-skill/skills/mindmap/render.sh`
- Test: `mindmap-skill/tests/test_render.sh` (add a case)

- [ ] **Step 1: Add the failing test case**

Edit `mindmap-skill/tests/test_render.sh` — insert this block **before** the final `finish` line:
```bash
# Case 3: npx not on PATH -> exit 3, prints manual command to stderr
empty="$(mktemp -d)"
err="$(PATH="$empty" bash "$RENDER" "$FIXTURE" 2>&1 >/dev/null)"; rc=$?
assert_eq 3 "$rc" "missing npx exits 3"
assert_contains "$err" "markmap-cli" "missing npx prints manual command"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash mindmap-skill/tests/test_render.sh`
Expected: FAIL — `render.sh` currently has no npx check, so with the fixture present it reaches the end of the script and exits `0`, not `3`.

- [ ] **Step 3: Extend the implementation**

Append to `mindmap-skill/skills/mindmap/render.sh`:
```bash
html="${2:-}"
if [ -z "$html" ]; then
  # swap trailing .md for .html (handles foo.mindmap.md -> foo.mindmap.html)
  html="${md%.md}.html"
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "error: npx not found; the .md is safe but HTML was not rendered." >&2
  echo "to render manually, install Node.js then run:" >&2
  echo "  npx markmap-cli \"$md\" -o \"$html\" --no-open" >&2
  exit 3
fi
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash mindmap-skill/tests/test_render.sh`
Expected: PASS — `(4 checks, 0 failed)`.

- [ ] **Step 5: Commit**

```bash
git add mindmap-skill/skills/mindmap/render.sh mindmap-skill/tests/test_render.sh
git commit -m "feat: render.sh degrades gracefully when npx is missing"
```

---

## Task 4: `render.sh` — success path and HTML-path derivation

With `npx` present, render the file and print the `.html` path on stdout. Tests use a **fake `npx`** so they never hit the network.

**Files:**
- Modify: `mindmap-skill/skills/mindmap/render.sh`
- Test: `mindmap-skill/tests/test_render.sh` (add cases)

- [ ] **Step 1: Add the failing test cases**

Edit `mindmap-skill/tests/test_render.sh` — insert this block **before** the final `finish` line:
```bash
# Build a fake npx that touches the file named after -o, so we never hit the network.
fakebin="$(mktemp -d)"
cat > "$fakebin/npx" <<'FAKE'
#!/usr/bin/env bash
out=""; prev=""
for a in "$@"; do
  [ "$prev" = "-o" ] && out="$a"
  prev="$a"
done
[ -n "$out" ] && printf '<html></html>' > "$out"
exit 0
FAKE
chmod +x "$fakebin/npx"

# Case 4: success -> exit 0, stdout is the derived .html path, file created
work="$(mktemp -d)"
cp "$FIXTURE" "$work/doc.mindmap.md"
out="$(PATH="$fakebin:$PATH" bash "$RENDER" "$work/doc.mindmap.md")"; rc=$?
assert_eq 0 "$rc" "success exits 0"
assert_eq "$work/doc.mindmap.html" "$out" "derives .html path from .md"
[ -f "$work/doc.mindmap.html" ] && created=yes || created=no
assert_eq "yes" "$created" "html file is created"

# Case 5: explicit output path is honored
out2="$(PATH="$fakebin:$PATH" bash "$RENDER" "$work/doc.mindmap.md" "$work/custom.html")"
assert_eq "$work/custom.html" "$out2" "honors explicit html path"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash mindmap-skill/tests/test_render.sh`
Expected: FAIL — `render.sh` has no success path yet; with the fake `npx` present it exits `0` but prints nothing, so the path assertions fail.

- [ ] **Step 3: Complete the implementation**

Append to `mindmap-skill/skills/mindmap/render.sh`:
```bash
if ! npx --yes markmap-cli "$md" -o "$html" --no-open >&2; then
  echo "error: markmap-cli failed; the .md is safe but HTML was not rendered." >&2
  exit 4
fi

echo "$html"
```

Note: `--yes` stops `npx` from blocking on an install prompt in non-interactive use. npx's own chatter is redirected to stderr (`>&2`) so the **only** thing on stdout is the final `.html` path.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash mindmap-skill/tests/test_render.sh`
Expected: PASS — `(8 checks, 0 failed)`.

- [ ] **Step 5: Verify the whole harness is green**

Run: `bash mindmap-skill/tests/run_tests.sh`
Expected: `== test_render.sh ==` block passes, then `ALL TESTS PASSED`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add mindmap-skill/skills/mindmap/render.sh mindmap-skill/tests/test_render.sh
git commit -m "feat: render.sh success path and html-path derivation"
```

---

## Task 5: `SKILL.md` frontmatter + validation test

The skill won't load if the YAML frontmatter is wrong. Lock it down with a structural test first.

**Files:**
- Create: `mindmap-skill/skills/mindmap/SKILL.md`
- Test: `mindmap-skill/tests/test_skill_frontmatter.sh`

- [ ] **Step 1: Write the failing test**

Create `mindmap-skill/tests/test_skill_frontmatter.sh`:
```bash
#!/usr/bin/env bash
# Validates SKILL.md frontmatter. Run: bash test_skill_frontmatter.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/lib.sh"
SKILL="$here/../skills/mindmap/SKILL.md"

[ -f "$SKILL" ] && exists=yes || exists=no
assert_eq "yes" "$exists" "SKILL.md exists"

# Frontmatter must be the first line and a delimited block.
first="$(head -n 1 "$SKILL" 2>/dev/null)"
assert_eq "---" "$first" "starts with frontmatter delimiter"

body="$(cat "$SKILL" 2>/dev/null)"
assert_contains "$body" "name: mindmap" "declares name: mindmap"
assert_contains "$body" "user-invocable: true" "is user-invocable"
assert_contains "$body" "allowed-tools: Bash, Read, Write, Glob" "declares allowed-tools"
assert_contains "$body" "description:" "has a description"

finish
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash mindmap-skill/tests/test_skill_frontmatter.sh`
Expected: FAIL — `SKILL.md` does not exist; `SKILL.md exists` fails and the rest report missing strings.

- [ ] **Step 3: Write the frontmatter (minimal SKILL.md)**

Create `mindmap-skill/skills/mindmap/SKILL.md`:
```text
---
name: mindmap
user-invocable: true
description: Generate an interactive Markmap mindmap from a file, pasted text, or a topic.
allowed-tools: Bash, Read, Write, Glob
---

# Mindmap Skill — Generate an Interactive Markmap

## Trigger
`/mindmap <input> [--render] [--output <path>]`
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash mindmap-skill/tests/test_skill_frontmatter.sh`
Expected: PASS — `(6 checks, 0 failed)`.

- [ ] **Step 5: Commit**

```bash
git add mindmap-skill/skills/mindmap/SKILL.md mindmap-skill/tests/test_skill_frontmatter.sh
git commit -m "feat: mindmap SKILL.md frontmatter + validation test"
```

---

## Task 6: `SKILL.md` instructional body

Fill in the workflow, format spec, worked example, and error handling — the heart of the skill. A second structural test guards the required sections.

**Files:**
- Modify: `mindmap-skill/skills/mindmap/SKILL.md`
- Test: `mindmap-skill/tests/test_skill_body.sh`

- [ ] **Step 1: Write the failing test**

Create `mindmap-skill/tests/test_skill_body.sh`:
```bash
#!/usr/bin/env bash
# Validates SKILL.md required sections. Run: bash test_skill_body.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/lib.sh"
SKILL="$here/../skills/mindmap/SKILL.md"
body="$(cat "$SKILL" 2>/dev/null)"

assert_contains "$body" "## Workflow" "has Workflow section"
assert_contains "$body" "hybrid" "documents hybrid structure logic"
assert_contains "$body" "## Markmap Format" "has Markmap Format section"
assert_contains "$body" "colorFreezeLevel: 2" "format keeps frontmatter defaults"
assert_contains "$body" "## Worked Example" "has Worked Example section"
assert_contains "$body" ".mindmap.md" "documents default output filename"
assert_contains "$body" "--render" "documents --render flag"
assert_contains "$body" "--output" "documents --output flag"
assert_contains "$body" "render.sh" "calls render.sh for --render"
assert_contains "$body" "4–7" "states the 4-7 branch guardrail"

finish
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash mindmap-skill/tests/test_skill_body.sh`
Expected: FAIL — the body sections aren't written yet; most checks report missing strings.

- [ ] **Step 3: Replace SKILL.md with the full version**

Overwrite `mindmap-skill/skills/mindmap/SKILL.md` with this complete content:
````text
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
2. Else if it is **multi-line, or long prose** (roughly > 12 words, or contains line breaks), treat it as **raw text**. That is the content.
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
- **Legibility over completeness:** for a very large source, map its structure and key points — not every line. Target **4–7 main branches**; condense aggressively.

### Step 3: Write the Markmap `.md`
Write a file in the exact shape shown under **Markmap Format** below.

Output path:
- File input `foo.md` → `foo.mindmap.md` (same directory).
- Topic input → `<topic-slug>.mindmap.md` in the current directory (slug = lowercase, spaces → `-`).
- `--output <path>` overrides the default.
- If the target already exists, write `<name>.mindmap.md`; if that is taken too, suffix `-2`, `-3`, … **Never overwrite silently.** (Use Glob to check for collisions.)

After writing, tell the user the exact path and how to view it: open it at https://markmap.js.org or with the VS Code “Markmap” extension.

### Step 4 (only with `--render`): Render to HTML
Run the helper from the skill directory:

```
bash <skill-dir>/render.sh "<output.md>"
```

- On success it prints the `.html` path on stdout — report it to the user.
- If it exits non-zero (e.g. `npx` not available, exit code 3), the `.md` is still the guaranteed deliverable. Tell the user rendering was skipped and show the manual command it printed. Do **not** treat this as a failure of the whole task.

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
````

- [ ] **Step 4: Run both SKILL tests to verify they pass**

Run: `bash mindmap-skill/tests/test_skill_body.sh && bash mindmap-skill/tests/test_skill_frontmatter.sh`
Expected: PASS — body test `(10 checks, 0 failed)`, frontmatter test `(6 checks, 0 failed)`.

- [ ] **Step 5: Run the full harness**

Run: `bash mindmap-skill/tests/run_tests.sh`
Expected: all three `test_*.sh` blocks pass, then `ALL TESTS PASSED`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add mindmap-skill/skills/mindmap/SKILL.md mindmap-skill/tests/test_skill_body.sh
git commit -m "feat: full mindmap SKILL.md body (workflow, format, example, errors)"
```

---

## Task 7: Install to `.claude/skills` and acceptance test

Make the skill discoverable, then verify end-to-end against real inputs (these exercise Claude's judgment and so are run manually).

**Files:**
- Create: `.claude/skills/mindmap/SKILL.md` (copy)
- Create: `.claude/skills/mindmap/render.sh` (copy)

- [ ] **Step 1: Install the skill into the project skills directory**

Run:
```bash
mkdir -p .claude/skills/mindmap
cp mindmap-skill/skills/mindmap/SKILL.md mindmap-skill/skills/mindmap/render.sh .claude/skills/mindmap/
ls .claude/skills/mindmap/
```
Expected: lists `SKILL.md` and `render.sh`.

Note: `.claude/skills/<name>/` is the project-local discovery location. The canonical source stays in `mindmap-skill/`; re-run this copy after any edit to the source. (If a `/reload-skills` command exists in your harness, run it; otherwise restart Claude Code so `/mindmap` registers.)

- [ ] **Step 2: Acceptance — structured file**

In Claude Code, run: `/mindmap LLM智能体记忆系统研究报告.md`
Then validate the output structurally:
```bash
f="LLM智能体记忆系统研究报告.mindmap.md"
echo "H1 count: $(grep -c '^# ' "$f")    (expect 1)"
echo "H2 count: $(grep -c '^## ' "$f")   (expect 4-7)"
head -n 6 "$f"                            # expect title + markmap frontmatter
```
Expected: exactly one `# ` line, 4–7 `## ` lines, frontmatter with `colorFreezeLevel: 2` and `maxWidth: 300`. Open the file at https://markmap.js.org — it renders as a clean, legible map.

- [ ] **Step 3: Acceptance — pasted text**

Run (one line): `/mindmap "Caching cuts latency and cost. Cache hit rate depends on TTL and key design. Eviction can be LRU or LFU. Watch for stampedes and stale reads."`
Expected: a `.mindmap.md` with one H1 and a few branches (e.g. Benefits / Hit rate / Eviction / Risks) — concept extraction, not a verbatim copy.

- [ ] **Step 4: Acceptance — topic prompt**

Run: `/mindmap "transformer attention"`
Expected: `transformer-attention.mindmap.md` with a coherent 4–7 branch map generated from knowledge (e.g. Q/K/V, scaled dot-product, multi-head, positional info).

- [ ] **Step 5: Acceptance — `--render`**

Run: `/mindmap "transformer attention" --render`
Expected: the `.md` is written **and** `render.sh` prints a `.html` path; opening the `.html` shows the interactive, zoomable map. (First `npx markmap-cli` run may take a moment while it fetches the package.)

- [ ] **Step 6: Acceptance — edge cases**

- Run `/mindmap missing-file.md` → Claude reports `no file at missing-file.md` and offers to map it as a topic (does **not** silently invent content).
- Run `/mindmap ""` → Claude asks for content or a topic.
- Re-run `/mindmap "transformer attention"` → the second run writes `transformer-attention-2.mindmap.md` (no silent overwrite).
- Simulate missing npx for the renderer:
  ```bash
  empty="$(mktemp -d)"; PATH="$empty" bash mindmap-skill/skills/mindmap/render.sh mindmap-skill/tests/fixtures/sample.mindmap.md; echo "exit=$?"
  ```
  Expected: prints the manual `npx markmap-cli ...` command and `exit=3`.

- [ ] **Step 7: Commit**

```bash
git add .claude/skills/mindmap/SKILL.md .claude/skills/mindmap/render.sh
git commit -m "chore: install mindmap skill into .claude/skills"
```

---

## Self-Review (completed during planning)

**Spec coverage** — every spec section maps to a task:
- Markmap `.md` output → Task 6 (Markmap Format) + acceptance Step 2.
- Inputs file/text/topic → Task 6 Step 1 (Resolve the input) + acceptance Steps 2–4.
- Hybrid structure → Task 6 Step 2.
- `--render` / HTML → Tasks 2–4 (render.sh) + Task 6 Step 4 + acceptance Step 5.
- `--output` + default `<inputname>.mindmap.md` + collision suffix → Task 6 Step 3 + acceptance Step 6.
- Frontmatter defaults (`colorFreezeLevel: 2`, `maxWidth: 300`) → Task 6 (Markmap Format), asserted in `test_skill_body.sh`.
- Sizing guardrail (4–7 branches) → Task 6, asserted in `test_skill_body.sh`.
- Error-handling table → Task 6 Step 1 (file-not-found, empty, ambiguous), Step 3 (collision), Step 4 (render degradation); render exit codes proven in Tasks 2–4.
- `render.sh` contract (exit codes 0/1/2/3/4, default html = swap `.md`→`.html`) → Tasks 2–4.
- Dependencies (zero by default; npx for render) → Task 6 Notes; degradation proven in Task 3.

**Placeholder scan:** none — every code/prose step shows complete content.

**Type/name consistency:** `render.sh` exit codes (1/2/3/4) are defined in Task 2 and reused identically in Tasks 3, 4, 6, and 7. The default filename suffix `.mindmap.md`, the flags `--render`/`--output`, and the frontmatter keys are used identically across SKILL.md, tests, and acceptance steps.
