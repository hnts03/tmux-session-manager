#!/usr/bin/env bash
# Integration tests for: tsm save --all / tsm restore --all
set -uo pipefail

PASS=0
FAIL=0
SOCKET="tsm-restore-all-test"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TSM="$REPO_DIR/bin/tsm"
SESSIONS_DIR="$(mktemp -d)"
FAKE_BIN="$(mktemp -d)"

cleanup() {
  command tmux -L "$SOCKET" kill-server 2>/dev/null || true
  rm -rf "$SESSIONS_DIR" "$FAKE_BIN"
}
trap cleanup EXIT

# Put a tmux wrapper early in PATH so tsm (child process) also uses our socket
cat > "$FAKE_BIN/tmux" << EOF
#!/bin/sh
exec $(command -v tmux) -L "$SOCKET" "\$@"
EOF
chmod +x "$FAKE_BIN/tmux"
export PATH="$FAKE_BIN:$PATH"

export TSM_SESSIONS_DIR="$SESSIONS_DIR"
export TMUX=""  # simulate outside-tmux context

t() { command tmux -L "$SOCKET" "$@"; }  # local helper

# ─── helpers ─────────────────────────────────────────────────────────────────

pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1"; echo "        ${2:-}"; (( FAIL++ )) || true; }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then pass "$desc"
  else fail "$desc" "expected='$expected' got='$actual'"; fi
}

assert_session_exists() {
  if t has-session -t "=$1" 2>/dev/null; then pass "session '$1' exists"
  else fail "session '$1' exists" "not found"; fi
}

assert_session_missing() {
  if ! t has-session -t "=$1" 2>/dev/null; then pass "session '$1' absent"
  else fail "session '$1' absent" "session still exists"; fi
}

win_count()  { t list-windows -t "=$1" 2>/dev/null | wc -l | tr -d ' '; }
pane_count() { t list-panes -s -t "=$1" 2>/dev/null | wc -l | tr -d ' '; }

# ─── setup: create test sessions ─────────────────────────────────────────────

echo ""
echo "[ setup: creating test sessions ]"

# Session A: 2 windows (editor=1 pane, server=2 panes)
t new-session -d -s sess_a -n "editor"
t new-window  -t sess_a    -n "server"
t split-window -t "sess_a:server" -h

# Session B: 1 window, 3 panes
t new-session -d -s sess_b -n "main"
t split-window -t "sess_b:main" -v
t split-window -t "sess_b:main" -h

# Session C: 3 windows, 1 pane each
t new-session -d -s sess_c -n "alpha"
t new-window  -t sess_c -n "beta"
t new-window  -t sess_c -n "gamma"

echo "  created: sess_a (2 windows), sess_b (3 panes), sess_c (3 windows)"

# ─── test: save --all ────────────────────────────────────────────────────────

echo ""
echo "[ tsm save --all ]"

save_out=$("$TSM" save --all 2>&1) || true

for name in sess_a sess_b sess_c; do
  if [[ -f "$SESSIONS_DIR/${name}.yaml" ]]; then pass "saved ${name}.yaml"
  else fail "saved ${name}.yaml" "file not found; tsm output: $save_out"; fi
done

# ─── kill all sessions, restart server ───────────────────────────────────────

echo ""
echo "[ killing all sessions ]"

t kill-server 2>/dev/null || true
# Need at least one session for the server to be running during restore
t new-session -d -s _placeholder 2>/dev/null

assert_session_missing sess_a
assert_session_missing sess_b
assert_session_missing sess_c

# ─── test: restore --all ─────────────────────────────────────────────────────

echo ""
echo "[ tsm restore --all ]"

restore_out=$("$TSM" restore --all 2>&1) || true

if echo "$restore_out" | grep -q "restored 3"; then pass "summary: 3 restored"
else fail "summary: 3 restored" "got: $restore_out"; fi

# ─── verify session structure ─────────────────────────────────────────────────

echo ""
echo "[ verifying restored structure ]"

assert_session_exists sess_a
assert_session_exists sess_b
assert_session_exists sess_c

assert_eq "sess_a: 2 windows"  "2" "$(win_count  sess_a)"
assert_eq "sess_b: 3 panes"    "3" "$(pane_count sess_b)"
assert_eq "sess_c: 3 windows"  "3" "$(win_count  sess_c)"

# window names
a_wins=$(t list-windows -t "=sess_a" -F '#{window_name}' | tr '\n' ',')
if echo "$a_wins" | grep -q "editor" && echo "$a_wins" | grep -q "server"; then
  pass "sess_a window names: editor, server"
else
  fail "sess_a window names" "got: $a_wins"
fi

c_wins=$(t list-windows -t "=sess_c" -F '#{window_name}' | tr '\n' ',')
if echo "$c_wins" | grep -q "alpha" && echo "$c_wins" | grep -q "beta" && echo "$c_wins" | grep -q "gamma"; then
  pass "sess_c window names: alpha, beta, gamma"
else
  fail "sess_c window names" "got: $c_wins"
fi

# ─── test: session already exists → skip gracefully, others still restored ───

echo ""
echo "[ restore --all: already-existing sessions are skipped, not fatal ]"

# sess_a/b/c exist now; add a new sess_d and save it
t new-session -d -s sess_d -n "extra"
"$TSM" save sess_d 2>/dev/null

partial_out=$("$TSM" restore --all 2>&1) || true

# sess_d must be restored even though a/b/c failed
if t has-session -t "=sess_d" 2>/dev/null; then
  pass "sess_d restored despite other failures"
else
  fail "sess_d restored despite other failures" "output: $partial_out"
fi

if echo "$partial_out" | grep -qE "failed|Failed"; then
  pass "failure count reported for already-existing sessions"
else
  fail "failure count reported" "got: $partial_out"
fi

# ─── test: empty sessions dir ────────────────────────────────────────────────

echo ""
echo "[ restore --all: empty sessions dir ]"

EMPTY="$(mktemp -d)"
empty_out=$(TSM_SESSIONS_DIR="$EMPTY" "$TSM" restore --all 2>&1) || true
if echo "$empty_out" | grep -q "no saved configs"; then
  pass "empty dir: correct error message"
else
  fail "empty dir: correct error message" "got: $empty_out"
fi
rmdir "$EMPTY"

# ─── result ──────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
