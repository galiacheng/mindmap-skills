# Installation

[README](../README.md) | [Chinese](installation.zh.md) | [Usage](usage.md)

Choose one installation method. The Skills CLI installs individual skills; the plugin marketplace installs the collection for Claude Code or GitHub Copilot.

## Skills CLI (skills.sh)

Requires [Node.js](https://nodejs.org) and Git.

```bash
# Choose skills and target agents interactively
npx skills add galiacheng/mindmap-skills

# Install only the English or Chinese skill
npx skills add galiacheng/mindmap-skills --skill mindmap
npx skills add galiacheng/mindmap-skills --skill mindmap-zh

# Install both skills for GitHub Copilot in the current project
npx skills add galiacheng/mindmap-skills --skill mindmap mindmap-zh --agent github-copilot

# List available skills without installing
npx skills add galiacheng/mindmap-skills --list
```

Installation is project-local by default; add `--global` to make the skills available across projects.

### Listing on skills.sh

[skills.sh](https://skills.sh/galiacheng/mindmap-skills) discovers and ranks skills through anonymous CLI installation statistics; no separate submission is required. Listing skills with `--list` is not an installation, and directory updates may not be immediate. See the [official FAQ](https://skills.sh/docs/faq).

## Claude Code plugin

Run inside Claude Code:

```text
/plugin marketplace add https://github.com/galiacheng/mindmap-skills.git
/plugin install mindmap@mindmap-marketplace
/reload-plugins
```

The explicit `https://` URL avoids an SSH clone. The `galiacheng/mindmap-skills` shorthand also works if you have GitHub SSH keys configured; otherwise it fails with `Permission denied (publickey)`.

## GitHub Copilot plugin

```bash
copilot plugin marketplace add galiacheng/mindmap-skills
copilot plugin install mindmap@mindmap-marketplace
```

Then run `/mindmap` or `/mindmap-zh` in your session. On GitHub Copilot the workflow is the same, using equivalent tool names; see the [Copilot tool mapping](../skills/mindmap/references/copilot-tools.md).

Claude Code and GitHub Copilot share the plugin/marketplace format. The marketplace manifest lives at [`.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json).

## Manual installation (Claude Code)

From a local clone of this repository, copy the skills into your project's or user-level skills directory. These commands use Bash:

```bash
# Project-local
mkdir -p .claude/skills
cp -r skills/mindmap skills/mindmap-zh .claude/skills/

# Or user-level (available in every project)
mkdir -p ~/.claude/skills
cp -r skills/mindmap skills/mindmap-zh ~/.claude/skills/
```

Then run `/reload-skills` or restart Claude Code. Confirm with `/help` that `/mindmap` and `/mindmap-zh` are listed.
