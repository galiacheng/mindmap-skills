#!/usr/bin/env bash
# Checks workflow model defaults and CLI arguments without making API calls.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/lib.sh"
WORKFLOW="$here/../.github/workflows/generate-mindmap.yml"

model="$(awk '
  /^      model:/ { in_model=1; next }
  in_model && /^        default:/ { print $2; exit }
' "$WORKFLOW")"
effort="$(awk '
  /^      reasoning_effort:/ { in_effort=1; next }
  in_effort && /^        default:/ { print $2; exit }
' "$WORKFLOW")"
assert_eq "gpt-6-astra" "$model" "defaults to GPT-6 Astra"
assert_eq "max" "$effort" "defaults to maximum reasoning effort"
language="$(awk '
  /^      language:/ { in_language=1; next }
  in_language && /^        default:/ { print $2; exit }
' "$WORKFLOW")"
assert_eq "en" "$language" "preserves English as the workflow default"
language_options="$(awk '
  /^      language:/ { in_language=1; next }
  in_language && /^      [a-z_]+:/ { exit }
  in_language && /^          - / { print $2 }
' "$WORKFLOW")"
assert_eq "20" "$(printf '%s\n' "$language_options" | wc -l | tr -d '[:space:]')" "workflow offers 19 languages plus auto"

script="$(awk '
  /^      - name: Generate mindmap with Copilot CLI/ { in_step=1; next }
  in_step && /^        run: \|/ { in_script=1; next }
  in_script && /^      - name:/ { exit }
  in_script { sub(/^          /, ""); print }
' "$WORKFLOW")"
assert_contains "$script" 'MODEL_ARGS=' "extracts the generation step"

copilot() { printf '%s\n' "$@"; }
export -f copilot

run_generation() {
  COPILOT_GITHUB_TOKEN=workflow-test-token \
  GITHUB_WORKSPACE="$here/.." \
  MINDMAP_INPUT="A test topic" \
  RENDER="${4:-false}" PANEL="${5:-false}" \
  OUTPUT_LANGUAGE="${3:-$language}" \
  MODEL="$1" REASONING_EFFORT="$2" \
  bash -c "$script"
}

out="$(run_generation "$model" "$effort" 2>&1)"; code=$?
assert_eq "0" "$code" "default model configuration succeeds"
assert_contains "$out" $'--model\ngpt-6-astra\n' "passes the default model to Copilot"
assert_contains "$out" $'--reasoning-effort\nmax\n' "passes maximum effort to Copilot"
assert_contains "$out" 'Apply these skill flags: --lang en' "passes the default output language to the skill"

codes=(en auto zh-Hans zh-Hant ja ko tr ru vi th de es fr uk pl pt-BR ar fa id it)
for code in "${codes[@]}"; do
  listed="$(printf '%s\n' "$language_options" | grep -Fx -- "$code")"
  assert_eq "$code" "$listed" "workflow offers $code"
  out="$(run_generation "$model" "$effort" "$code" 2>&1)"; rc=$?
  assert_eq "0" "$rc" "$code selection succeeds"
  assert_contains "$out" "Apply these skill flags: --lang $code" "passes $code to the skill"
done

for alias in zh zh-CN ZH-HANS; do
  out="$(run_generation "$model" "$effort" "$alias" 2>&1)"; rc=$?
  assert_eq "0" "$rc" "$alias alias succeeds"
  assert_contains "$out" 'Apply these skill flags: --lang zh-Hans' "normalizes $alias"
done
for alias in zh-TW ZH-HANT; do
  out="$(run_generation "$model" "$effort" "$alias" 2>&1)"; rc=$?
  assert_eq "0" "$rc" "$alias alias succeeds"
  assert_contains "$out" 'Apply these skill flags: --lang zh-Hant' "normalizes $alias"
done
out="$(run_generation "$model" "$effort" "PT-br" true true 2>&1)"; rc=$?
assert_eq "0" "$rc" "case-insensitive language with panel and render succeeds"
assert_contains "$out" 'Apply these skill flags: --lang pt-BR --panel --render' "language selection preserves other skill flags"

for invalid in unsupported 'ja --render' 'ja; echo injected'; do
  out="$(run_generation "$model" "$effort" "$invalid" 2>&1)"; rc=$?
  assert_eq "1" "$rc" "rejects invalid language: $invalid"
  assert_contains "$out" '::error::Unsupported output language:' "explains invalid language"
  assert_not_contains "$out" '--plugin-dir' "invalid language stops before invoking Copilot"
done

out="$(run_generation "custom-model" "default" 2>&1)"; code=$?
assert_eq "0" "$code" "model-specific effort configuration succeeds"
assert_contains "$out" $'--model\ncustom-model\n' "preserves a model override"
assert_not_contains "$out" "--reasoning-effort" "default effort leaves selection to the model"

out="$(run_generation "custom-model" "high" 2>&1)"; code=$?
assert_eq "0" "$code" "explicit effort override succeeds"
assert_contains "$out" $'--reasoning-effort\nhigh\n' "passes an effort override to Copilot"

body="$(cat "$WORKFLOW")"
assert_contains "$body" 'REASONING_EFFORT: ${{ inputs.reasoning_effort }}' "binds the workflow effort input"
assert_contains "$body" 'reasoning effort: `%s`' "records reasoning effort in the PR description"
assert_contains "$body" 'OUTPUT_LANGUAGE: ${{ inputs.language }}' "binds the workflow language input"
assert_contains "$body" 'requested output language: `%s`' "records requested language in the PR description"

finish
