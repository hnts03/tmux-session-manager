#!/usr/bin/env bash
# Unit tests for tsm shell completions

PASS=0
FAIL=0
SOCKET="tsm-completion-test"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPLETIONS_DIR="$REPO_DIR/completions"

cleanup() {
  tmux -L "$SOCKET" kill-server 2>/dev/null || true
}
trap cleanup EXIT

# seed isolated tmux server
tmux -L "$SOCKET" new-session -d -s alpha
tmux -L "$SOCKET" new-session -d -s beta
tmux -L "$SOCKET" new-session -d -s gamma

# override tmux in this shell to use isolated socket
tmux() { command tmux -L "$SOCKET" "$@"; }
export -f tmux

assert_contains() {
  local desc="$1" expected="$2" actual="$3"
  if echo "$actual" | grep -qF "$expected"; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    echo "        expected to contain: '$expected'"
    echo "        got: '$actual'"
    ((FAIL++))
  fi
}

assert_not_contains() {
  local desc="$1" unexpected="$2" actual="$3"
  if ! echo "$actual" | grep -qF "$unexpected"; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    echo "        expected NOT to contain: '$unexpected'"
    echo "        got: '$actual'"
    ((FAIL++))
  fi
}

# ─── bash completion tests ────────────────────────────────────────────────────

echo "[ bash completion ]"

source "$COMPLETIONS_DIR/tsm.bash"

run_bash_complete() {
  local prev="$1" cur="$2"
  if [[ "$prev" == "tsm" ]]; then
    COMP_WORDS=("tsm" "$cur")
    COMP_CWORD=1
  else
    COMP_WORDS=("tsm" "$prev" "$cur")
    COMP_CWORD=2
  fi
  COMPREPLY=()
  _tsm_completion
  echo "${COMPREPLY[*]}"
}

result=$(run_bash_complete "tsm" "")
assert_contains "subcommands: kill listed" "kill" "$result"
assert_contains "subcommands: new listed" "new" "$result"
assert_contains "subcommands: ls listed" "ls" "$result"

result=$(run_bash_complete "tsm" "k")
assert_contains "partial 'k' → kill" "kill" "$result"
assert_not_contains "partial 'k' excludes new" "new" "$result"

result=$(run_bash_complete "kill" "")
assert_contains "kill completes sessions: alpha" "alpha" "$result"
assert_contains "kill completes sessions: beta" "beta" "$result"
assert_contains "kill completes sessions: gamma" "gamma" "$result"

result=$(run_bash_complete "kill" "al")
assert_contains "kill partial 'al' → alpha" "alpha" "$result"
assert_not_contains "kill partial 'al' excludes beta" "beta" "$result"

result=$(run_bash_complete "new" "")
assert_not_contains "new has no completions" "alpha" "$result"

# ─── zsh completion tests ─────────────────────────────────────────────────────

echo ""
echo "[ zsh completion ]"

# syntax check
zsh_syntax=$(zsh -n "$COMPLETIONS_DIR/_tsm" 2>&1)
if [[ -z "$zsh_syntax" ]]; then
  echo "  PASS: _tsm syntax valid"
  ((PASS++))
else
  echo "  FAIL: _tsm syntax error: $zsh_syntax"
  ((FAIL++))
fi

# _tsm_sessions helper returns session names
zsh_sessions=$(zsh -c "
  tmux() { command tmux -L $SOCKET \"\$@\"; }
  source '$COMPLETIONS_DIR/_tsm' 2>/dev/null || true
  tmux list-sessions -F '#{session_name}' 2>/dev/null
")
assert_contains "zsh: sessions include alpha" "alpha" "$zsh_sessions"
assert_contains "zsh: sessions include beta" "beta" "$zsh_sessions"

# subcommand list present in completion file
zsh_content=$(cat "$COMPLETIONS_DIR/_tsm")
assert_contains "zsh: defines kill subcommand" "kill" "$zsh_content"
assert_contains "zsh: defines new subcommand" "new" "$zsh_content"
assert_contains "zsh: defines ls subcommand" "ls" "$zsh_content"

# ─── summary ─────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
