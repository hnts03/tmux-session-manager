#!/usr/bin/env bash
# Integration tests for full command-line capture on save + restore --with-commands.
set -uo pipefail

PASS=0
FAIL=0
SOCKET="tsm-cmdcap-test"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TSM="$REPO_DIR/bin/tsm"
SESSIONS_DIR="$(mktemp -d)"
LOGS_DIR="$(mktemp -d)"
FAKE_BIN="$(mktemp -d)"

cleanup() {
  command tmux -L "$SOCKET" kill-server 2>/dev/null || true
  rm -rf "$SESSIONS_DIR" "$LOGS_DIR" "$FAKE_BIN"
}
trap cleanup EXIT

cat > "$FAKE_BIN/tmux" << EOF
#!/bin/sh
exec $(command -v tmux) -L "$SOCKET" "\$@"
EOF
chmod +x "$FAKE_BIN/tmux"
export PATH="$FAKE_BIN:$PATH"
export TSM_SESSIONS_DIR="$SESSIONS_DIR"
export TSM_LOGS_DIR="$LOGS_DIR"
export TMUX=""

t() { command tmux -L "$SOCKET" "$@"; }
pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1"; echo "        ${2:-}"; (( FAIL++ )) || true; }

# Run a foreground command in a pane and give the shell a moment to exec it.
run_in_pane() { t send-keys -t "$1" "$2" Enter; sleep 1.5; }

# ─── capture: command_line records args ──────────────────────────────────────

echo ""
echo "[ save captures the full command line (with args) ]"

t new-session -d -s cap -n main
run_in_pane cap:main 'sleep 314'

# sanity: tmux itself must see the pane's foreground as 'sleep'
if [[ "$(t display-message -t cap:main -p '#{pane_current_command}')" == "sleep" ]]; then
  pass "tmux foreground is 'sleep'"
else
  fail "tmux foreground is 'sleep'" "got '$(t display-message -t cap:main -p '#{pane_current_command}')' — send-keys may not have run"
fi

"$TSM" save cap >/dev/null 2>&1
if grep -q "command_line: 'sleep 314'" "$SESSIONS_DIR/cap.yaml"; then
  pass "yaml has command_line: 'sleep 314'"
else
  fail "yaml command_line" "got: $(grep command_line "$SESSIONS_DIR/cap.yaml" || echo none)"
fi

# ─── restore --with-commands re-runs the full line ───────────────────────────

echo ""
echo "[ restore --with-commands re-runs the captured line ]"

t kill-session -t cap 2>/dev/null
t new-session -d -s _ph 2>/dev/null
"$TSM" restore --with-commands --no-attach cap >/dev/null 2>&1
sleep 1.5
if [[ "$(t display-message -t cap:main -p '#{pane_current_command}' 2>/dev/null)" == "sleep" ]]; then
  pass "restored pane is running sleep again"
else
  fail "restore re-ran command" "foreground='$(t display-message -t cap:main -p '#{pane_current_command}' 2>/dev/null)'"
fi

# ─── backward compat: yaml without command_line falls back to command ────────

echo ""
echo "[ backward compat: config without command_line uses 'command' ]"

t new-session -d -s old -n main
run_in_pane old:main 'cat'          # cat waits on stdin; runnable by name alone
"$TSM" save old >/dev/null 2>&1
# simulate a pre-command_line config by stripping the field
grep -v 'command_line:' "$SESSIONS_DIR/old.yaml" > "$SESSIONS_DIR/old.tmp" && mv "$SESSIONS_DIR/old.tmp" "$SESSIONS_DIR/old.yaml"
if grep -q 'command_line:' "$SESSIONS_DIR/old.yaml"; then
  fail "strip command_line for fixture" "still present"
fi
t kill-session -t old 2>/dev/null
"$TSM" restore --with-commands --no-attach old >/dev/null 2>&1
sleep 1.5
if [[ "$(t display-message -t old:main -p '#{pane_current_command}' 2>/dev/null)" == "cat" ]]; then
  pass "fell back to 'command' (cat) when command_line absent"
else
  fail "backward-compat fallback" "foreground='$(t display-message -t old:main -p '#{pane_current_command}' 2>/dev/null)'"
fi

# ─── prompt-idle shell is skipped (login shell '-zsh' must not be re-run) ────

echo ""
echo "[ an idle shell pane is not re-run (login-shell '-zsh' still skipped) ]"

t new-session -d -s idle -n main    # pane sits at the shell prompt
sleep 0.5
"$TSM" save idle >/dev/null 2>&1
t kill-session -t idle 2>/dev/null
"$TSM" restore --with-commands --no-attach idle >/dev/null 2>&1
sleep 1
idle_pane=$(t capture-pane -p -t idle:main 2>/dev/null)
if ! grep -qiE 'not found|-zsh|-bash' <<<"$idle_pane"; then
  pass "idle shell not re-run (no bogus command in pane)"
else
  fail "idle shell skipped" "pane shows: $(echo "$idle_pane" | grep -iE 'not found|-zsh|-bash' | head -1)"
fi

# ─── result ──────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
