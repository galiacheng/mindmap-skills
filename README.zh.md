# mindmap

[English](README.md) | [中文](README.zh.md)

[![skills.sh](https://skills.sh/b/galiacheng/mindmap-skills)](https://skills.sh/galiacheng/mindmap-skills)

**一眼读懂任何材料——在你的 AI 编码助手里，把文件、URL 或主题直接变成思维导图。**

`mindmap` 是一个适用于 [Claude Code](https://docs.claude.com/en/docs/claude-code) 与 [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/copilot-cli) 的插件。把它指向一份密集的报告、一篇长文，或仅仅一个主题，它就会把关键内容提炼成清晰、可缩放的 [Markmap](https://markmap.js.org) 思维导图——就在你的终端里完成。

> 一个插件，两种语言：`/mindmap`（英文）与 `/mindmap-zh`（中文）。

---

## 一眼看懂

一条命令，把一篇很长的 GitHub 博客文章变成思维导图：

```
/mindmap-zh https://github.blog/ai-and-ml/how-we-made-github-copilot-cli-more-selective-about-delegation/ --render
```

一篇约 1500 词的文章，变成几秒就能读完的结构：

```
# 更聪明的子智能体委派
├── 问题
│   ├── 委派很强大，但并非没有代价
│   └── 多余的交接、重复的检索、等待
├── 方法
│   ├── 分析 → 定位委派瓶颈
│   ├── 改进 → 简单任务主智能体直接做
│   └── 验证 → 先离线、再在线、最后发布
├── 结果
│   ├── 每次会话工具失败 −23%
│   └── 等待时间 P95 −5%，质量无回退
└── 下一步
```

这是真实输出——完整的 Markmap `.md` 与渲染后的可交互 `.html` 见 [`examples/`](examples/)（用浏览器打开即可缩放、折叠分支）。

**▶ [打开在线可交互思维导图](https://galiacheng.github.io/mindmap-skills/examples/copilot-cli-selective-delegation.mindmap.html)** —— 无需安装，点击即看。

---

## 为什么用它

- **快速读懂密集材料** — 把一份 3000 词的报告收拢为 5–7 个分支，一眼扫完，而不必从头读到尾。
- **一条命令，任意来源** — 文件、URL、粘贴的笔记，或仅一个主题。无需复制粘贴到另一个网页工具。
- **不打断你的工作流** — 在 Claude Code / Copilot CLI 内运行；导图作为文件就落在你工作的旁边。
- **智能结构，而非文本堆砌** — 沿用已有结构的大纲，或把松散文本提炼为 4–7 个简洁分支。节点是短语，不是句子。
- **可移植、可交互的产物** — 标准 Markmap `.md`，到哪都能打开；外加一个可分享的独立 `.html`。

**适用场景：** 速览研究论文与报告 · 消化博客文章与文档 · 动笔前先梳理主题 · 把会议记录变成可分享的导图。

---

## 安装

同一个仓库既是 Claude Code 的有效插件，也是 GitHub Copilot CLI 的有效插件——二者共用插件/市场（marketplace）格式。

### Skills CLI（skills.sh）

无需添加插件市场，也可以直接安装独立技能。需要 [Node.js](https://nodejs.org) 和 Git。

```bash
# 交互选择技能和目标智能体
npx skills add galiacheng/mindmap-skills

# 仅安装英文版或中文版
npx skills add galiacheng/mindmap-skills --skill mindmap
npx skills add galiacheng/mindmap-skills --skill mindmap-zh

# 为当前项目的 GitHub Copilot 安装两个技能
npx skills add galiacheng/mindmap-skills --skill mindmap mindmap-zh --agent github-copilot
```

默认安装到当前项目；添加 `--global` 可供所有项目使用。仅查看可用技能而不安装，可运行 `npx skills add galiacheng/mindmap-skills --list`。

[skills.sh](https://skills.sh/galiacheng/mindmap-skills) 根据 CLI 的匿名安装统计自动收录并排名，无需另行提交。`--list` 不算安装，目录更新也不一定即时生效。详见[官方 FAQ](https://skills.sh/docs/faq)。

### Claude Code

```
/plugin marketplace add https://github.com/galiacheng/mindmap-skills.git
/plugin install mindmap@mindmap-marketplace
/reload-plugins
```

> 使用显式的 `https://` 地址可避免走 SSH 克隆。`galiacheng/mindmap-skills` 简写形式也可用，**前提是**你已配置 GitHub SSH 密钥；否则会报 `Permission denied (publickey)`。

### GitHub Copilot CLI

```bash
copilot plugin marketplace add galiacheng/mindmap-skills
copilot plugin install mindmap@mindmap-marketplace
```

随后在会话中运行 `/mindmap`（英文）或 `/mindmap-zh`（中文）。在 Copilot CLI 上工作流相同，工具名会自动映射（见 [`skills/mindmap-zh/references/copilot-tools.md`](skills/mindmap-zh/references/copilot-tools.md)）。

市场清单位于 [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)。

### 手动安装（本地，不经市场）

把技能复制到项目级（或用户级）的 skills 目录：

```bash
# 项目级
mkdir -p .claude/skills
cp -r skills/mindmap skills/mindmap-zh .claude/skills/

# 或用户级（在所有项目中可用）
mkdir -p ~/.claude/skills
cp -r skills/mindmap skills/mindmap-zh ~/.claude/skills/
```

随后运行 `/reload-skills`（或重启 Claude Code）。用 `/help` 确认 `/mindmap` 与 `/mindmap-zh` 已列出。

---

## 用法

```
/mindmap-zh <输入> [--render] [--output <路径>]
```

| 输入 | 示例 | 行为 |
|---|---|---|
| **文件** | `/mindmap-zh 报告.md` | 读取文件，沿用其结构，压缩节点。写出 `报告.mindmap.md`。 |
| **URL** | `/mindmap-zh https://example.com/article` | 抓取页面（WebFetch），映射其内容。写出 `<页面-slug>.mindmap.md`。 |
| **粘贴文本** | `/mindmap-zh "关于 X、Y、Z 的笔记……"` | 提炼概念为分支。写出 `<标题-slug>.mindmap.md`。 |
| **主题** | `/mindmap-zh "向量数据库"` | 基于模型知识生成导图。写出 `向量数据库.mindmap.md`。 |

**参数**

- `--render` — 写出 `.md` 后，额外生成一个独立的可交互 `.html`（需要 Node.js / `npx`）。
- `--output <路径>` — 将 `.md` 写到指定路径，而非默认路径。

---

## 输出格式

技能写出 [Markmap](https://markmap.js.org) 风格的 markdown——单个 `#` 根节点、`##` 分支、嵌套列表项：

```markdown
---
title: 检索增强生成（RAG）
markmap:
  colorFreezeLevel: 2
  maxWidth: 300
---

# 检索增强生成（RAG）

## 索引
- 切分文档
- 嵌入片段
- 存储向量

## 检索
- 对查询做嵌入
- 找到最近邻片段

## 生成
- 注入上下文到提示词
```

**查看 `.md`：**
- 粘贴到 [markmap.js.org](https://markmap.js.org)，**或**
- 在 VS Code 中用 [Markmap 扩展](https://marketplace.visualstudio.com/items?itemName=gera2ld.markmap-vscode) 打开，**或**
- 用 `--render` 生成可在任意浏览器打开的 `.html`。

---

## 渲染为 HTML

```
/mindmap-zh "Transformer 注意力机制" --render
```

底层运行 `npx markmap-cli <文件>.md -o <文件>.html --no-open`（经由 [`skills/mindmap-zh/scripts/render.sh`](skills/mindmap-zh/scripts/render.sh)）。

- **`.md` 始终是有保证的交付物。** 渲染是尽力而为。
- 若未安装 `npx` / Node.js，技能仍会写出 `.md`，报告已跳过渲染，并打印可手动执行的确切命令——不会丢失任何内容。

**前置要求：** [Node.js](https://nodejs.org)（提供 `npx`）。无需全局安装——`npx` 会按需拉取 `markmap-cli`。

---

## 工作原理

这是一个**提示词驱动**的技能：智能体现在指令里，而非代码里。

```
skills/mindmap-zh/
├── SKILL.md            # Claude 遵循的工作流：判定输入 → 构建层级 → 写出 .md →（可选）渲染
├── scripts/
│   └── render.sh       # 唯一的代码 —— 对 `npx markmap-cli` 的薄封装
└── references/
    └── copilot-tools.md  # Claude Code → Copilot CLI 工具名映射
```

- [`SKILL.md`](skills/mindmap-zh/SKILL.md) 告诉 Claude 如何判定输入、应用混合式结构化规则、写出格式正确的 Markmap 文件，并处理边界情况（文件缺失、空输入、重名冲突、渲染回退）。
- [`scripts/render.sh`](skills/mindmap-zh/scripts/render.sh) 是一个约 35 行的 bash 辅助脚本，退出码明确（`0` 成功 · `1` 用法错误 · `2` 文件未找到 · `3` 缺少 npx · `4` 渲染失败）。成功时只在 stdout 打印 `.html` 路径。

完整设计见 [`docs/design-spec.md`](docs/design-spec.md)。

---

## 开发

渲染脚本带有 bash 测试套件（不联网——使用伪造的 `npx`）：

```bash
bash tests/run_tests.sh
```

预期：`ALL TESTS PASSED`（跨 `test_render.sh`、`test_skill_frontmatter.sh`、`test_skill_body.sh`、`test_skill_zh.sh` 共 45 项检查）。

```
mindmap/
├── .claude-plugin/
│   ├── plugin.json        # 插件清单
│   └── marketplace.json   # 市场清单（供 /plugin marketplace add 使用）
├── skills/
│   ├── mindmap/           # 英文技能（/mindmap）
│   └── mindmap-zh/        # 中文技能（/mindmap-zh）
├── tests/                 # render.sh + SKILL.md 结构的 bash 测试
├── examples/              # 实际生成的输出（.md + 渲染后的 .html）
├── docs/                  # 设计文档
├── LICENSE
└── README.md
```

---

## 许可证

[MIT](LICENSE) © 2026 Haixia Cheng
