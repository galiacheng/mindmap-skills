# Usage and advanced features

[README](../README.md) | [Chinese](usage.zh.md) | [Installation](installation.md)

## Compatibility

The skills describe capabilities rather than fixed tool names. They are intended for coding agents that support Agent Skills; installing with `npx skills` does not guarantee every feature works on every agent.

| Feature | Requirements | When unavailable |
|---|---|---|
| Basic `.md` output | Inspect paths and create files; read files for file input. | Explain the missing capability or permission and ask how to proceed; do not claim a file was saved. |
| URL input | Retrieve page content. | Ask for pasted content, a retry, or an explicitly chosen topic-based map. |
| `--render` | Execute the supplied helper with Bash and Node.js / `npx`. | Keep the `.md`, explain why HTML was not generated, and provide a manual rendering command. |
| `--panel` (`mindmap` only) | Delegate to independent subagents and collect results. | Explain the limitation and ask before switching to single-pass generation. |

The agent's permissions and approvals still apply. Examples use slash-command notation; if your agent does not expose slash commands, invoke `mindmap` or `mindmap-zh` through its supported skill mechanism.

## Inputs and flags

```text
/mindmap <input> [--lang <language|auto>] [--panel] [--render] [--output <path>]
/mindmap-zh <input> [--lang <language|auto>] [--render] [--output <path>]
```

| Input | Example | Behavior |
|---|---|---|
| File | `/mindmap report.md` | Reads the file, mirrors its structure, condenses nodes. Writes `report.mindmap.md`. |
| URL | `/mindmap https://example.com/article` | Fetches the page and maps its content. Writes `<page-slug>.mindmap.md`. |
| Pasted text | `/mindmap "notes about X, Y, Z..."` | Extracts concepts into branches. Writes `<title-slug>.mindmap.md`. |
| Topic | `/mindmap "vector databases"` | Generates a map from the model's knowledge. Writes `vector-databases.mindmap.md`. |

| Flag | Behavior |
|---|---|
| `--lang <code\|auto>` | Choose the output language, or use the resolved source's predominant language with `auto`. |
| `--render` | After writing the `.md`, also produce interactive `.html` (needs command execution, Bash, and Node.js / `npx`). |
| `--output <path>` | Write the `.md` to a specific path instead of the default. |
| `--panel` | Design the structure with independent subagents; `mindmap` only. |

The skill follows an existing outline or groups unstructured content into 4-7 main branches, aiming for 3-4 levels and short node labels. Existing output files are preserved by adding a numeric suffix, including when `--output` is specified.

### Languages

Both skills accept files, URLs, pasted text, and topics in these 19 languages. You do not need a separate skill installation for each output language.

| Language | Code | Aliases |
|---|---|---|
| English | `en` | — |
| 简体中文 | `zh-Hans` | `zh`, `zh-CN` |
| 繁體中文 | `zh-Hant` | `zh-TW` |
| 日本語 | `ja` | — |
| 한국어 | `ko` | — |
| Türkçe | `tr` | — |
| Русский | `ru` | — |
| Tiếng Việt | `vi` | — |
| ไทย | `th` | — |
| Deutsch | `de` | — |
| Español | `es` | — |
| Français | `fr` | — |
| Українська | `uk` | — |
| Polski | `pl` | — |
| Português (Brasil) | `pt-BR` | — |
| العربية | `ar` | — |
| فارسی | `fa` | — |
| Bahasa Indonesia | `id` | — |
| Italiano | `it` | — |

Codes are case-insensitive. An explicit `--lang` takes precedence; otherwise an explicit output-language request in the conversation is honored. Without either, `/mindmap` retains English output and `/mindmap-zh` retains Simplified Chinese output, even for foreign-language sources. Source content cannot override this choice.

`--lang auto` follows the loaded content, not the filename or URL, and distinguishes Simplified and Traditional Chinese. When mixed-language or language-neutral content has no clear predominant language, it uses the supported conversation language, otherwise the skill's default, and explains the choice. Missing, unsupported, or conflicting `--lang` values are reported before files are written.

Titles, headings, nodes, table prose, link labels, and user-facing explanations use the selected language. Code, identifiers, URLs, paths, proper names, and source numbers/units are preserved where translating would alter meaning. Output is UTF-8; accents, non-Latin filenames, and normal logical text order for Arabic/Persian are retained. Chinese, Japanese, and Thai prose is not classified by space-separated word count alone; labels stay concise without artificial spaces.

```text
/mindmap report.md --lang ja --render
/mindmap-zh 报告.md --lang zh-Hant
/mindmap "vector databases" --lang pt-BR
/mindmap https://example.com/article --lang auto
/mindmap report.md --lang ar --panel
```

The [Generate mindmap workflow](../.github/workflows/generate-mindmap.yml) also offers a `language` selector, defaulting to `en`, and passes it as `--lang` to the skill.

### Workflow

```mermaid
flowchart LR
    IN["Input<br/>file / URL / text / topic"] --> CL{Classify}
    CL -->|URL| FE[Fetch page]
    CL -->|file| RD[Read file]
    CL -->|prose| TX[Use as text]
    CL -->|topic| KN[Model knowledge]
    FE --> ST[Build hierarchy]
    RD --> ST
    TX --> ST
    KN --> ST
    ST --> WR["Write Markmap .md"]
    WR --> RN{--render?}
    RN -->|yes| HT["Interactive .html"]
    RN -->|no| MD[".md deliverable"]
```

## Output format

The skill writes [Markmap](https://markmap.js.org)-flavored Markdown: a single `#` root, `##` branches, and nested bullets.

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

To view the `.md`, paste it at [markmap.js.org](https://markmap.js.org), open it in VS Code with the [Markmap extension](https://marketplace.visualstudio.com/items?itemName=gera2ld.markmap-vscode), or use `--render` to generate HTML.

## Rendering to HTML

```text
/mindmap "transformer attention" --render
```

This uses the agent's command-execution capability to run the Bash helper [`render.sh`](../skills/mindmap/scripts/render.sh), which calls `npx --yes markmap-cli <file>.md -o <file>.html --no-open`. Open the generated `.html` in a browser to zoom and collapse branches.

**The `.md` is the guaranteed deliverable; HTML rendering is best-effort.** If command execution, Bash, or Node.js / `npx` is unavailable, the skill still writes the `.md`, explains the limitation, and prints a manual `npx` command for an environment with Node.js.

[Node.js](https://nodejs.org) provides `npx`; no global `markmap-cli` install is needed. `npx` fetches it on demand.

## The judge panel (`--panel`)

For complex or high-stakes sources such as papers and long reports, `/mindmap --panel` uses **3 proposers, 3 judges, and 1 synthesizer** instead of a single-pass structure.

The host must support independent subagent tasks. No particular workflow API is required; tasks can run in parallel or sequentially in separate contexts. If delegation is unavailable, the skill asks before continuing without `--panel` rather than simulating independent reviewers.

The selected output language is passed to every proposer, judge, and synthesizer; the panel checks it before writing the final map. `--panel` is not restricted to English output.

```text
/mindmap report.md --panel --render
```

```mermaid
flowchart TB
    SRC["Source content + skill rules"]
    subgraph PROPOSE["1 - Propose (3 lenses)"]
        P1["Proposer A<br/>narrative-first"]
        P2["Proposer B<br/>data-first"]
        P3["Proposer C<br/>audience-first"]
    end
    subgraph JUDGE["2 - Judge (score 10 dimensions)"]
        J1["Judge 1"]
        J2["Judge 2"]
        J3["Judge 3"]
    end
    subgraph SYNTH["3 - Synthesize"]
        SY["Top proposal = spine<br/>+ graft judges' best ideas"]
    end
    SRC --> P1 & P2 & P3
    P1 & P2 & P3 --> J1 & J2 & J3
    J1 & J2 & J3 --> SY
    SY --> OUT["Final Markmap .md"]
```

### 1. Propose

Three agents each design a full structure through a different lens:

| Lens | Designs the map around... |
|---|---|
| Narrative-first | The source's own arc and section order. |
| Data-first | The headline numbers and evidence, with metrics in **bold**. |
| Audience-first | The punchline first, with every leaf legible on a slide. |

Each proposer tags every node with a format and a render tier:

| Format | Tier | Best for |
|---|---|---|
| Bullet list | `core` | Parallel facts. |
| Bold inline | `core` | Headline metrics, emphasis. |
| Link | `core` | References, repositories, papers. |
| Table | `rich` | Comparisons, benchmark numbers. |
| Code block | `rich` | Formulas, reward functions, code. |
| Checkbox | `rich` | Tasks, limitations, checklists. |

### 2. Judge

Three judges independently score every proposal from 1-5 on ten dimensions: branch count, depth, phrasing, legibility, source fidelity, punchline-first, headline numbers, leaf legibility, visual balance, and format fit. Each judge also identifies each proposal's best idea.

### 3. Synthesize

One synthesizer uses the top-scored proposal as the spine, grafts in the best ideas identified by the judges, and emits the final Markmap `.md`.

**Cost:** the panel spawns about seven agents and is token-intensive. Without `--panel`, the skill uses a fast single pass. The Chinese `/mindmap-zh` skill does not include this flag.

The exact prompts and schemas live in the [judge-panel reference](../skills/mindmap/references/judge-panel.md). See [real examples](../examples/README.md) for panel-generated outputs.

Failed roles are reported explicitly. If all proposers fail, the skill announces a single-pass fallback. If no valid judge scorecards remain or synthesis fails, it asks whether to retry or continue without `--panel`.
