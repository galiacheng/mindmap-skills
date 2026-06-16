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
