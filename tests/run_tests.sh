#!/usr/bin/env bash
# Run every test_*.sh in this directory. Exit non-zero if any test fails.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
shopt -s nullglob
tests=("$here"/test_*.sh)
if [ "${#tests[@]}" -eq 0 ]; then
  echo "no test files yet"
  exit 0
fi
fail=0
for t in "${tests[@]}"; do
  echo "== $(basename "$t") =="
  bash "$t" || fail=1
done
if [ "$fail" -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "SOME TESTS FAILED"; fi
exit "$fail"
