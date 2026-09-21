#!/usr/bin/env bash
# Validates the Chinese skill (mindmap-zh). Run: bash test_skill_zh.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/lib.sh"
SKILL="$here/../skills/mindmap-zh/SKILL.md"
body="$(cat "$SKILL" 2>/dev/null)"

[ -f "$SKILL" ] && exists=yes || exists=no
assert_eq "yes" "$exists" "mindmap-zh SKILL.md exists"

first="$(head -n 1 "$SKILL" 2>/dev/null)"
assert_eq "---" "$first" "starts with frontmatter delimiter"

assert_contains "$body" "name: mindmap-zh" "declares name: mindmap-zh"
assert_contains "$body" "user-invocable: true" "is user-invocable"
assert_not_contains "$body" "allowed-tools:" "does not hard-code a host-specific tool allowlist"
assert_contains "$body" "/mindmap-zh" "documents the /mindmap-zh trigger"

# Required sections (Chinese headers)
assert_contains "$body" "## 工作流" "has Workflow section (工作流)"
assert_contains "$body" "## Markmap 格式" "has Markmap Format section"
assert_contains "$body" "colorFreezeLevel: 2" "format keeps frontmatter defaults"
assert_contains "$body" "## 示例" "has Worked Example section (示例)"
assert_contains "$body" ".mindmap.md" "documents default output filename"
assert_contains "$body" "--render" "documents --render flag"
assert_contains "$body" "--output" "documents --output flag"
assert_contains "$body" "render.sh" "calls render.sh for --render"
assert_contains "$body" "4–7" "states the 4-7 branch guardrail"
assert_contains "$body" "网页获取能力" "documents a capability for URL input"
assert_contains "$body" "URL" "documents URL as an input type"
assert_contains "$body" "## 智能体能力要求" "documents agent capability requirements"
assert_contains "$body" "宿主的权限" "respects host permissions"
assert_contains "$body" "无法检查或写入文件" "reports unavailable file access"
assert_contains "$body" "检查目标是否已存在" "preserves collision checks"
assert_contains "$body" "无法执行命令" "handles unavailable command execution"
assert_contains "$body" "Bash" "documents the render helper runtime requirement"
assert_not_contains "$body" "WebFetch" "does not require a named web tool"
assert_not_contains "$body" "Glob" "does not require a named file-search tool"

# The zh render.sh must stay byte-identical to the en one (no drift).
EN="$here/../skills/mindmap/scripts/render.sh"
ZH="$here/../skills/mindmap-zh/scripts/render.sh"
if cmp -s "$EN" "$ZH"; then identical=yes; else identical=no; fi
assert_eq "yes" "$identical" "zh render.sh is byte-identical to en render.sh"

finish
