#!/usr/bin/env bash
# Validates SKILL.md frontmatter. Run: bash test_skill_frontmatter.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/lib.sh"
SKILL="$here/../skills/mindmap/SKILL.md"

[ -f "$SKILL" ] && exists=yes || exists=no
assert_eq "yes" "$exists" "SKILL.md exists"

# Frontmatter must be the first line and a delimited block.
first="$(head -n 1 "$SKILL" 2>/dev/null)"
assert_eq "---" "$first" "starts with frontmatter delimiter"

body="$(cat "$SKILL" 2>/dev/null)"
assert_contains "$body" "name: mindmap" "declares name: mindmap"
assert_contains "$body" "user-invocable: true" "is user-invocable"
assert_contains "$body" "allowed-tools: Bash, Read, Write, Glob" "declares allowed-tools"
assert_contains "$body" "description:" "has a description"

finish
