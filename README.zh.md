# mindmap

[English](README.md) | [中文](README.zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e.svg)](LICENSE)
[![skills.sh](https://skills.sh/b/galiacheng/mindmap-skills)](https://skills.sh/galiacheng/mindmap-skills)

**在 AI 编码助手里，把文件、URL、粘贴的笔记或主题变成可缩放的思维导图。**

适用于 **Claude Code** 与 **GitHub Copilot**。输出 [Markmap](https://markmap.js.org) `.md`，也可生成可交互的 `.html`，用简洁分支代替大段文字。

两个技能：`/mindmap`（英文）和 `/mindmap-zh`（中文）。

## 一眼看懂

**[打开在线交互演示](https://galiacheng.github.io/mindmap-skills/examples/copilot-cli-selective-delegation.mindmap.html)** —— 由 GitHub 博客生成，可缩放、折叠，无需安装。

更多真实输出及生成命令见[示例](examples/README.md)。

## 安装

先安装 [Node.js](https://nodejs.org) 和 Git，然后运行：

```bash
npx skills add galiacheng/mindmap-skills
```

按提示选择技能和智能体。默认安装到当前项目；添加 `--global` 可供所有项目使用。

插件市场命令、指定智能体安装和手动安装方式见[安装指南](docs/installation.zh.md)。

## 用法

```text
/mindmap-zh 报告.md
/mindmap-zh https://example.com/article --render
/mindmap-zh "向量数据库" --output overview.mindmap.md
/mindmap "vector databases" --render
```

也可以直接传入粘贴的文本或笔记。

| 参数 | 作用 |
|---|---|
| `--render` | 同时生成可交互 HTML（需要 Node.js / `npx`）。 |
| `--output <路径>` | 指定输出路径。 |
| `--panel` | 用多智能体评审设计复杂导图；消耗较多 token，仅 `/mindmap` 支持。 |

`.md` 可在 [markmap.js.org](https://markmap.js.org) 或 [VS Code Markmap 扩展](https://marketplace.visualstudio.com/items?itemName=gera2ld.markmap-vscode)中查看；渲染后的 `.html` 用浏览器打开。

## 文档

| 指南 | 内容 |
|---|---|
| [安装指南](docs/installation.zh.md) | Skills CLI、Claude Code / Copilot 插件、手动安装、skills.sh 收录。 |
| [使用与高级功能](docs/usage.zh.md) | 输入处理、输出格式、HTML 渲染、多智能体评审。 |
| [示例](examples/README.md) | 在线导图与源文件。 |
| [贡献指南](CONTRIBUTING.md)（英文） | 项目结构、实现方式与测试。 |
| [设计文档](docs/design-spec.md)（英文） | 原始设计与取舍。 |

## 许可证

[MIT](LICENSE) © 2026 Haixia Cheng
