#!/usr/bin/env bash
# Tests for render.sh. Run: bash test_render.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/lib.sh"
RENDER="$here/../skills/mindmap/scripts/render.sh"
FIXTURE="$here/fixtures/sample.mindmap.md"

# Clean up all temp dirs created below, even if a check fails.
_tmpdirs=()
trap 'rm -rf "${_tmpdirs[@]}"' EXIT

# Case 1: no argument -> usage error, exit 1
bash "$RENDER" >/dev/null 2>&1; rc=$?
assert_eq 1 "$rc" "no arg exits 1 (usage)"

# Case 2: missing .md file -> exit 2
bash "$RENDER" "$here/fixtures/does-not-exist.md" >/dev/null 2>&1; rc=$?
assert_eq 2 "$rc" "missing md exits 2"

# Case 3: npx not on PATH -> exit 3, prints manual command to stderr
# Note: launch via "$BASH" (absolute path) so emptying PATH hides npx from the
# child without also making the bash interpreter itself unresolvable.
empty="$(mktemp -d)"; _tmpdirs+=("$empty")
err="$(PATH="$empty" "$BASH" "$RENDER" "$FIXTURE" 2>&1 >/dev/null)"; rc=$?
assert_eq 3 "$rc" "missing npx exits 3"
assert_contains "$err" "markmap-cli" "missing npx prints manual command"

# Build a fake npx that touches the file named after -o, so we never hit the network.
fakebin="$(mktemp -d)"; _tmpdirs+=("$fakebin")
cat > "$fakebin/npx" <<'FAKE'
#!/usr/bin/env bash
echo "npx noise on stdout that must not leak"
[ -z "${NPX_ARGS_FILE:-}" ] || printf '%s\n' "$@" > "$NPX_ARGS_FILE"
out=""; prev=""
for a in "$@"; do
  [ "$prev" = "-o" ] && out="$a"
  prev="$a"
done
[ -n "$out" ] && printf '<html></html>' > "$out"
exit 0
FAKE
chmod +x "$fakebin/npx"

# Case 4: success -> exit 0, stdout is the derived .html path, file created
work="$(mktemp -d)"; _tmpdirs+=("$work")
cp "$FIXTURE" "$work/doc.mindmap.md"
out="$(PATH="$fakebin:$PATH" bash "$RENDER" "$work/doc.mindmap.md")"; rc=$?
assert_eq 0 "$rc" "success exits 0"
assert_eq "$work/doc.mindmap.html" "$out" "derives .html path from .md"
[ -f "$work/doc.mindmap.html" ] && created=yes || created=no
assert_eq "yes" "$created" "html file is created"

# Case 5: explicit output path is honored
out2="$(PATH="$fakebin:$PATH" bash "$RENDER" "$work/doc.mindmap.md" "$work/custom.html")"
assert_eq "$work/custom.html" "$out2" "honors explicit html path"

# Build a fake npx that FAILS, to exercise the exit-4 (render failed) branch.
failbin="$(mktemp -d)"; _tmpdirs+=("$failbin")
cat > "$failbin/npx" <<'FAKE'
#!/usr/bin/env bash
echo "boom" >&2
exit 1
FAKE
chmod +x "$failbin/npx"

# Case 6: npx present but markmap-cli fails -> exit 4
PATH="$failbin:$PATH" bash "$RENDER" "$work/doc.mindmap.md" >/dev/null 2>&1; rc=$?
assert_eq 4 "$rc" "render failure exits 4"

# Unicode paths and content must reach the renderer unchanged for both skills.
labels=('English' '简体中文' '繁體中文' '日本語' '한국어' 'Türkçe' 'Русский' 'Tiếng Việt' 'ไทย' 'Deutsch' 'Español' 'Français' 'Українська' 'Polski' 'Português Brasil' 'العربية' 'فارسی' 'Bahasa Indonesia' 'Italiano')
for label in "${labels[@]}"; do
  md="$work/$label.mindmap.md"
  printf '%s\n' '---' "title: $label" 'markmap:' '  colorFreezeLevel: 2' '  maxWidth: 300' '---' '' "# $label" '' "## $label" "- $label" > "$md"
  original="$(cat "$md")"
  expected_args="$(printf '%s\n' --yes markmap-cli "$md" -o "${md%.md}.html" --no-open)"
  for helper in "$RENDER" "$here/../skills/mindmap-zh/scripts/render.sh"; do
    out="$(NPX_ARGS_FILE="$work/npx-args" PATH="$fakebin:$PATH" bash "$helper" "$md" 2>/dev/null)"; rc=$?
    assert_eq 0 "$rc" "$label renders through $(basename "$(dirname "$(dirname "$helper")")") helper"
    assert_eq "${md%.md}.html" "$out" "$label output path preserves Unicode and spaces"
    assert_eq "$expected_args" "$(cat "$work/npx-args")" "$label passes paths as intact arguments"
    assert_eq "$original" "$(cat "$md")" "$label source content is unchanged"
  done
done

finish
