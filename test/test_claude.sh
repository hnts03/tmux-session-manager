#!/usr/bin/env bash
# Integration tests for: tsm claude --status  +  the __claude-hook producer.
set -uo pipefail

PASS=0
FAIL=0
SOCKET="tsm-claude-test"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TSM="$REPO_DIR/bin/tsm"
FAKE_BIN="$(mktemp -d)"

cleanup() {
  command tmux -L "$SOCKET" kill-server 2>/dev/null || true
  rm -rf "$FAKE_BIN"
}
trap cleanup EXIT

# tmux wrapper so tsm (child) talks to the isolated socket
cat > "$FAKE_BIN/tmux" << EOF
#!/bin/sh
exec $(command -v tmux) -L "$SOCKET" "\$@"
EOF
chmod +x "$FAKE_BIN/tmux"
cat > "$FAKE_BIN/fzf" << 'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$FAKE_BIN/fzf"
export PATH="$FAKE_BIN:$PATH"

t() { command tmux -L "$SOCKET" "$@"; }
pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1"; echo "        ${2:-}"; (( FAIL++ )) || true; }

# ─── setup: two panes in two sessions ────────────────────────────────────────

P1=$(t new-session -d -s work -n main -P -F '#{pane_id}')
P2=$(t new-session -d -s dev  -n main -P -F '#{pane_id}')

echo ""
echo "[ __claude-hook stamps the pane's state ]"

TMUX_PANE="$P1" "$TSM" __claude-hook running
TMUX_PANE="$P2" "$TSM" __claude-hook waiting

o1=$(t show-options -pv -t "$P1" @claude_state 2>/dev/null)
o2=$(t show-options -pv -t "$P2" @claude_state 2>/dev/null)
[[ "$o1" == running@* ]] && pass "P1 stamped running@<epoch>" || fail "P1 stamp" "got '$o1'"
[[ "$o2" == waiting@* ]] && pass "P2 stamped waiting@<epoch>" || fail "P2 stamp" "got '$o2'"

echo ""
echo "[ tsm claude --status shows both, with state + target ]"

# Compute each pane's target dynamically — window/pane indices depend on the
# server's base-index (0 by default, 1 if the user's tmux.conf sets it).
TGT1=$(t display-message -t "$P1" -p '#{session_name}:#{window_index}.#{pane_index}')
TGT2=$(t display-message -t "$P2" -p '#{session_name}:#{window_index}.#{pane_index}')
out=$("$TSM" claude --status 2>&1)
echo "$out" | grep -- "$TGT1" | grep -q "running" && pass "shows running for $TGT1" \
  || fail "status running" "got: $out"
echo "$out" | grep -- "$TGT2" | grep -q "waiting" && pass "shows waiting for $TGT2" \
  || fail "status waiting" "got: $out"

echo ""
echo "[ tsm cc --status is an alias for tsm claude --status ]"
cc_out=$("$TSM" cc --status 2>&1)
[[ "$cc_out" == "$out" ]] && pass "cc --status == claude --status" || fail "cc alias" "differs"

echo ""
echo "[ a stale 'running' (older than the TTL) is flagged ]"
t set-option -p -t "$P1" @claude_state "running@$(( $(date +%s) - 99999 ))"
"$TSM" claude --status 2>&1 | grep -qi "stale" && pass "old running → stale" \
  || fail "staleness" "not flagged: $("$TSM" claude --status 2>&1)"

echo ""
echo "[ clear removes the pane's state (SessionEnd hook) ]"
TMUX_PANE="$P2" "$TSM" __claude-hook clear
o2c=$(t show-options -pv -t "$P2" @claude_state 2>/dev/null || true)
[[ -z "$o2c" ]] && pass "P2 state cleared" || fail "clear" "still '$o2c'"

echo ""
echo "[ no reporting panes → helpful message ]"
t set-option -pu -t "$P1" @claude_state 2>/dev/null || true
empty_out=$("$TSM" claude --status 2>&1)
echo "$empty_out" | grep -qi "no claude code panes" && pass "empty state message" \
  || fail "empty message" "got: $empty_out"

echo ""
echo "[ __claude-hook outside tmux is a no-op (no crash) ]"
( unset TMUX_PANE; "$TSM" __claude-hook running >/dev/null 2>&1 ) && pass "no-op without TMUX_PANE" \
  || fail "no-op without TMUX_PANE" "returned non-zero"

echo ""
echo "────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
