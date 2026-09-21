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
assert_contains "$body" "web-fetch capability" "documents a capability for URL input"
assert_contains "$body" "URL" "documents URL as an input type"

assert_contains "$body" "## Agent capabilities" "documents agent capability requirements"
assert_contains "$body" "host's permissions" "respects host permissions"
assert_contains "$body" "cannot inspect or write files" "reports unavailable file access"
assert_contains "$body" "check whether the target already exists" "preserves collision checks"
assert_contains "$body" "no independent subagent capability" "handles unavailable panel support"
assert_contains "$body" "ask whether to continue without" "does not silently downgrade an unavailable panel"
assert_contains "$body" "Bash" "documents the render helper runtime requirement"
assert_contains "$body" "cannot execute commands" "handles unavailable command execution"
assert_not_contains "$body" "WebFetch" "does not require a named web tool"
assert_not_contains "$body" "Glob" "does not require a named file-search tool"
assert_not_contains "$body" "**Workflow** tool" "does not require a named orchestration tool"

panel="$(cat "$here/../skills/mindmap/references/judge-panel.md" 2>/dev/null)"
assert_contains "$panel" "## Execution protocol" "provides a portable panel execution protocol"
assert_contains "$panel" "sequentially" "allows hosts without parallel dispatch"
assert_contains "$panel" "Validate each result" "validates results without requiring a schema API"
assert_contains "$panel" "all proposers fail" "preserves the announced single-pass fallback"
assert_contains "$panel" "no valid judge scorecards" "handles an unavailable judging result"
assert_not_contains "$panel" 'Workflow `schema`' "does not require a host-specific schema API"
assert_not_contains "$panel" "export const meta" "does not require a host-specific workflow module"

finish
