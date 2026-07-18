#!/usr/bin/env bash
# Run every integration test in this directory and summarise the result.
# Usage: test/run_all.sh
# Exit status is non-zero if any suite fails.
set -uo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"

# Preflight: the suites need these on PATH.
missing=()
for dep in tmux fzf yq; do
  command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
done
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "run_all: missing dependencies: ${missing[*]}" >&2
  echo "         install them and retry (tests exercise the real script)." >&2
  exit 2
fi

shopt -s nullglob
suites=("$TEST_DIR"/test_*.sh)
shopt -u nullglob

if [[ ${#suites[@]} -eq 0 ]]; then
  echo "run_all: no test_*.sh files found in $TEST_DIR" >&2
  exit 2
fi

passed=0
failed=0
failed_names=()

for suite in "${suites[@]}"; do
  name="$(basename "$suite")"
  echo ""
  echo "══════════════════════════════════════════════"
  echo "▶ $name"
  echo "══════════════════════════════════════════════"
  if bash "$suite"; then
    (( passed++ )) || true
  else
    (( failed++ )) || true
    failed_names+=("$name")
  fi
done

echo ""
echo "══════════════════════════════════════════════"
echo "SUITES: $passed passed, $failed failed"
if [[ $failed -gt 0 ]]; then
  echo "FAILED: ${failed_names[*]}"
  exit 1
fi
echo "All suites passed."
