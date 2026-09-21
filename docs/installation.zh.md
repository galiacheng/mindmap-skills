# 安装指南

[README](../README.zh.md) | [English](installation.md) | [使用指南](usage.zh.md)

选择一种安装方式即可。Skills CLI 安装独立技能；插件市场为 Claude Code 或 GitHub Copilot 安装整套插件。

## Skills CLI（skills.sh）

需要 [Node.js](https://nodejs.org) 和 Git。

```bash
# 交互选择技能和目标智能体
npx skills add galiacheng/mindmap-skills

# 仅安装英文版或中文版
npx skills add galiacheng/mindmap-skills --skill mindmap
npx skills add galiacheng/mindmap-skills --skill mindmap-zh

# 为当前项目的 GitHub Copilot 安装两个技能
npx skills add galiacheng/mindmap-skills --skill mindmap mindmap-zh --agent github-copilot

# 只列出可用技能，不安装
npx skills add galiacheng/mindmap-skills --list
```

默认安装到当前项目；添加 `--global` 可供所有项目使用。

### skills.sh 收录

[skills.sh](https://skills.sh/galiacheng/mindmap-skills) 根据 CLI 的匿名安装统计自动收录并排名，无需另行提交。`--list` 不算安装，目录更新也不一定即时生效。详见[官方 FAQ](https://skills.sh/docs/faq)。

## Claude Code 插件

在 Claude Code 内运行：

```text
/plugin marketplace add https://github.com/galiacheng/mindmap-skills.git
/plugin install mindmap@mindmap-marketplace
/reload-plugins
```

使用显式的 `https://` 地址可避免走 SSH 克隆。`galiacheng/mindmap-skills` 简写形式也可用，前提是已配置 GitHub SSH 密钥；否则会报 `Permission denied (publickey)`。

## GitHub Copilot 插件

```bash
copilot plugin marketplace add galiacheng/mindmap-skills
copilot plugin install mindmap@mindmap-marketplace
```

随后在会话中运行 `/mindmap` 或 `/mindmap-zh`。在 GitHub Copilot 上工作流相同，使用等效工具名，见 [Copilot 工具映射](../skills/mindmap-zh/references/copilot-tools.md)。

Claude Code 和 GitHub Copilot 共用插件/市场格式。市场清单位于 [`.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json)。

## 手动安装（Claude Code）

在本仓库的本地克隆目录中，把技能复制到项目级或用户级 skills 目录。以下命令使用 Bash：

```bash
# 项目级
mkdir -p .claude/skills
cp -r skills/mindmap skills/mindmap-zh .claude/skills/

# 或用户级（在所有项目中可用）
mkdir -p ~/.claude/skills
cp -r skills/mindmap skills/mindmap-zh ~/.claude/skills/
```

随后运行 `/reload-skills` 或重启 Claude Code。用 `/help` 确认 `/mindmap` 与 `/mindmap-zh` 已列出。
