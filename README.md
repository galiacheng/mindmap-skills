<div align="center">

# 🧠 mindmap

**An agent skill that turns files, URLs, notes, and topics into interactive mindmaps.**

[English](README.md) · [中文](README.zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e.svg)](LICENSE)
[![skills.sh](https://skills.sh/b/galiacheng/mindmap-skills)](https://skills.sh/galiacheng/mindmap-skills)

</div>

For coding agents that support **Agent Skills** and the [required capabilities](docs/usage.md#compatibility). Produces [Markmap](https://markmap.js.org) `.md` files and optional interactive `.html`, with concise branches instead of a wall of text.

Two skills: `/mindmap` (English) and `/mindmap-zh` (中文).

## 👀 See it

**[Open the live interactive demo](https://galiacheng.github.io/mindmap-skills/examples/copilot-cli-selective-delegation.mindmap.html)** — zoom and collapse a mindmap generated from a GitHub blog post. No install needed.

More real outputs and source commands: [examples](examples/README.md).

## 📦 Install

With [Node.js](https://nodejs.org) and Git installed:

```bash
npx skills add galiacheng/mindmap-skills
```

Choose your skill and agent. Installation is project-local by default; add `--global` for all projects.

For plugin marketplace commands, agent-specific installation, and manual setup, see the [installation guide](docs/installation.md).

## ⚡ Usage

```text
/mindmap report.md
/mindmap https://example.com/article --render
/mindmap "vector databases" --output overview.mindmap.md
/mindmap-zh "向量数据库" --render
```

You can also pass pasted text or notes directly. Examples use slash-command notation; invoke the skill through your agent's supported mechanism.

| Flag | Purpose |
|---|---|
| `--render` | Also generate interactive HTML (requires command execution, Bash, and Node.js / `npx`). |
| `--output <path>` | Choose the output path. |
| `--panel` | Use a multi-agent judge panel; requires independent subagents, is token-intensive, and is available in `mindmap` only. |

Open the `.md` at [markmap.js.org](https://markmap.js.org) or with the [VS Code Markmap extension](https://marketplace.visualstudio.com/items?itemName=gera2ld.markmap-vscode); open rendered `.html` in a browser.

## Documentation

| Guide | Covers |
|---|---|
| [Installation](docs/installation.md) | Skills CLI, plugin marketplaces, manual setup, skills.sh listing. |
| [Usage and advanced features](docs/usage.md) | Compatibility, input behavior, output format, HTML rendering, judge panel. |
| [Examples](examples/README.md) | Live mindmaps and their source files. |
| [Contributing](CONTRIBUTING.md) | Project structure, implementation, and tests. |
| [Design spec](docs/design-spec.md) | Original design and rationale. |

## 📄 License

[MIT](LICENSE) © 2026 Haixia Cheng
