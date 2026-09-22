# Contributing

Thanks for your interest in improving `mindmap`! This guide covers how the skill
is structured and how to run the tests.

## 🛠️ How it works

This is a **prompt-driven** skill: the intelligence lives in instructions, not code.

```
skills/mindmap/
├── SKILL.md              # the workflow: resolve input → build hierarchy → write .md → (optional) render
├── scripts/
│   ├── render.sh         # thin wrapper around `npx markmap-cli` (the .md → .html step)
│   └── degrade-rich.mjs  # rewrites rich nodes (tables/code/checkboxes) to bullets for the poster path
└── references/
    ├── copilot-tools.md  # optional Copilot setup notes and tool examples
    └── judge-panel.md    # portable --panel prompts, output shapes, and protocol
```

- [`SKILL.md`](skills/mindmap/SKILL.md) tells the agent how to classify the input, apply the hybrid structuring rules, write a well-formed Markmap file, and handle edge cases (missing capabilities, missing files, empty input, name collisions, render fallback). Describe capabilities rather than host-specific tool IDs, and keep the [compatibility guide](docs/usage.md#compatibility) aligned with both skills.
- [`scripts/render.sh`](skills/mindmap/scripts/render.sh) is a ~35-line bash helper with deterministic exit codes (`0` ok · `1` usage · `2` file not found · `3` npx missing · `4` render failed). On success it prints only the `.html` path to stdout.

See [`docs/design-spec.md`](docs/design-spec.md) for the full design.

## 🧪 Development

The render helper has a bash test suite (no network — it uses a fake `npx`):

```bash
bash tests/run_tests.sh
```

Expected: `ALL TESTS PASSED` across `test_render.sh`, `test_skill_frontmatter.sh`, `test_skill_body.sh`, `test_skill_zh.sh`, and `test_workflow.sh`. Skill checks cover portable capability requirements as well as structure and frontmatter. Workflow checks cover model defaults and CLI arguments without making API calls.

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
├── docs/                  # installation, usage, compatibility, and design
├── LICENSE
└── README.md
```
