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
  RENDER=false PANEL=false \
  MODEL="$1" REASONING_EFFORT="$2" \
  bash -c "$script"
}

out="$(run_generation "$model" "$effort" 2>&1)"; code=$?
assert_eq "0" "$code" "default model configuration succeeds"
assert_contains "$out" $'--model\ngpt-6-astra\n' "passes the default model to Copilot"
assert_contains "$out" $'--reasoning-effort\nmax\n' "passes maximum effort to Copilot"

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

finish
