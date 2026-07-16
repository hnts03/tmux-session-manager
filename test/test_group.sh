#!/usr/bin/env bash
# Integration tests for: tsm group save / restore / list / delete
set -uo pipefail

PASS=0
FAIL=0
SOCKET="tsm-group-test"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TSM="$REPO_DIR/bin/tsm"
SESSIONS_DIR="$(mktemp -d)"
CFG_HOME="$(mktemp -d)"     # XDG_CONFIG_HOME → groups live under $CFG_HOME/tsm/groups
LOGS_DIR="$(mktemp -d)"
FAKE_BIN="$(mktemp -d)"

cleanup() {
  command tmux -L "$SOCKET" kill-server 2>/dev/null || true
  rm -rf "$SESSIONS_DIR" "$CFG_HOME" "$LOGS_DIR" "$FAKE_BIN"
}
trap cleanup EXIT

# tmux wrapper so tsm (child process) also uses our isolated socket
cat > "$FAKE_BIN/tmux" << EOF
#!/bin/sh
exec $(command -v tmux) -L "$SOCKET" "\$@"
EOF
chmod +x "$FAKE_BIN/tmux"
export PATH="$FAKE_BIN:$PATH"

export TSM_SESSIONS_DIR="$SESSIONS_DIR"
export TSM_LOGS_DIR="$LOGS_DIR"
export XDG_CONFIG_HOME="$CFG_HOME"
export TMUX=""   # simulate outside-tmux context

t() { command tmux -L "$SOCKET" "$@"; }

pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1"; echo "        ${2:-}"; (( FAIL++ )) || true; }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then pass "$desc"
  else fail "$desc" "expected='$expected' got='$actual'"; fi
}

win_count()  { t list-windows -t "=$1" 2>/dev/null | wc -l | tr -d ' '; }
pane_count() { t list-panes -s -t "=$1" 2>/dev/null | wc -l | tr -d ' '; }

GROUPS_DIR="$CFG_HOME/tsm/groups"

# ─── setup ───────────────────────────────────────────────────────────────────

echo ""
echo "[ setup: creating test sessions ]"

# alpha: 1 window, 2 panes
t new-session -d -s alpha -n main
t split-window -t "alpha:main" -h
# beta: 2 windows, 1 pane each
t new-session -d -s beta -n one
t new-window  -t beta -n two
# gamma: not part of the group (must stay untouched)
t new-session -d -s gamma -n solo

echo "  created: alpha (2 panes), beta (2 windows), gamma (excluded)"

# ─── test: group save ────────────────────────────────────────────────────────

echo ""
echo "[ tsm group save work alpha beta ]"

save_out=$("$TSM" group save work alpha beta 2>&1) || true

if [[ -f "$GROUPS_DIR/work.yaml" ]]; then pass "group manifest work.yaml created"
else fail "group manifest work.yaml created" "not found; output: $save_out"; fi

# member session configs must also have been snapshotted
for name in alpha beta; do
  if [[ -f "$SESSIONS_DIR/${name}.yaml" ]]; then pass "member config ${name}.yaml snapshotted"
  else fail "member config ${name}.yaml snapshotted" "not found"; fi
done

# gamma must NOT be in the group
if grep -q "gamma" "$GROUPS_DIR/work.yaml" 2>/dev/null; then
  fail "gamma excluded from group" "gamma present in manifest"
else
  pass "gamma excluded from group"
fi

# ─── test: group list ────────────────────────────────────────────────────────

echo ""
echo "[ tsm group list ]"

list_out=$("$TSM" group list 2>&1) || true
if echo "$list_out" | grep -q "work" && echo "$list_out" | grep -q "alpha" && echo "$list_out" | grep -q "beta"; then
  pass "group list shows work with members"
else
  fail "group list shows work with members" "got: $list_out"
fi

# ─── kill all sessions, keep server alive ────────────────────────────────────

echo ""
echo "[ killing all sessions ]"

t kill-server 2>/dev/null || true
t new-session -d -s _placeholder 2>/dev/null

if t has-session -t "=alpha" 2>/dev/null; then fail "alpha killed" "still exists"; else pass "alpha killed"; fi
if t has-session -t "=beta"  2>/dev/null; then fail "beta killed"  "still exists"; else pass "beta killed"; fi

# ─── test: group restore ─────────────────────────────────────────────────────

echo ""
echo "[ tsm group restore work ]"

restore_out=$("$TSM" group restore work 2>&1) || true

if echo "$restore_out" | grep -q "restored group 'work' — 2"; then pass "summary: 2 restored"
else fail "summary: 2 restored" "got: $restore_out"; fi

assert_eq "alpha: 2 panes"   "2" "$(pane_count alpha)"
assert_eq "beta: 2 windows"  "2" "$(win_count  beta)"

# gamma must not have been recreated by the group restore
if t has-session -t "=gamma" 2>/dev/null; then
  fail "gamma not restored by group" "gamma exists (should not)"
else
  pass "gamma not restored by group"
fi

# ─── test: restore is non-fatal when a member already runs ───────────────────

echo ""
echo "[ group restore: already-running members are skipped, not fatal ]"

partial_out=$("$TSM" group restore work 2>&1) || true
if echo "$partial_out" | grep -qE "failed"; then
  pass "already-running members reported as failed, run continues"
else
  fail "already-running members reported as failed" "got: $partial_out"
fi

# ─── test: group delete keeps member configs ─────────────────────────────────

echo ""
echo "[ tsm group delete work (member configs preserved) ]"

del_out=$(printf 'y\n' | "$TSM" group delete work 2>&1) || true
if [[ ! -f "$GROUPS_DIR/work.yaml" ]]; then pass "group manifest deleted"
else fail "group manifest deleted" "still exists; output: $del_out"; fi

if [[ -f "$SESSIONS_DIR/alpha.yaml" && -f "$SESSIONS_DIR/beta.yaml" ]]; then
  pass "member session configs preserved after group delete"
else
  fail "member session configs preserved after group delete" "a member config was removed"
fi

# ─── test: restore a non-existent group errors cleanly ───────────────────────

echo ""
echo "[ group restore: missing group ]"

miss_out=$("$TSM" group restore nope 2>&1) || true
if echo "$miss_out" | grep -q "not found"; then
  pass "missing group: correct error message"
else
  fail "missing group: correct error message" "got: $miss_out"
fi

# ─── result ──────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
