# lib.sh — minimal bash test helpers. Source this from each test_*.sh.
# Usage: source lib.sh; assert_eq "$expected" "$actual" "label"; ...; finish
_tests_run=0
_tests_failed=0

assert_eq() { # expected actual label
  _tests_run=$((_tests_run + 1))
  if [ "$1" = "$2" ]; then
    echo "  ok: $3"
  else
    _tests_failed=$((_tests_failed + 1))
    echo "  FAIL: $3 (expected '$1', got '$2')" >&2
  fi
}

assert_contains() { # haystack needle label
  _tests_run=$((_tests_run + 1))
  case "$1" in
    *"$2"*) echo "  ok: $3" ;;
    *) _tests_failed=$((_tests_failed + 1)); echo "  FAIL: $3 (missing '$2')" >&2 ;;
  esac
}

finish() { # returns non-zero if any assertion failed
  echo "  ($_tests_run checks, $_tests_failed failed)"
  [ "$_tests_failed" -eq 0 ]
}
