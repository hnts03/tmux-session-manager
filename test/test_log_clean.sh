#!/usr/bin/env bash
# Tests for `tsm log clean` — especially the guards that stop an empty session/dir
# from widening `rm -rf` to the whole logs directory (data-loss regression).
set -uo pipefail

PASS=0
FAIL=0
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TSM="$REPO_DIR/bin/tsm"
FAKE_BIN="$(mktemp -d)"

cleanup() { rm -rf "$FAKE_BIN"; }
trap cleanup EXIT

# Fake tmux: `-V` reports a version; `display-message -p #S` returns $FAKE_SESSION.
cat > "$FAKE_BIN/tmux" <<'EOF'
#!/bin/sh
if [ "$1" = "-V" ]; then echo "tmux 3.3"; exit 0; fi
case "$*" in
  *"-p #S"*) printf '%s' "${FAKE_SESSION-}" ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/tmux"
cat > "$FAKE_BIN/fzf" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$FAKE_BIN/fzf"

pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1"; echo "        $2"; (( FAIL++ )) || true; }

# Fresh logs dir with two sessions' logs
new_logs() {
  local d; d="$(mktemp -d)"
  mkdir -p "$d/work" "$d/play"
  echo x > "$d/work/0.0.log"
  echo y > "$d/play/0.0.log"
  echo "$d"
}

echo ""
echo "[ guard: empty current session must NOT delete the logs dir ]"
LOGS="$(new_logs)"
out=$(env TMUX=fake FAKE_SESSION="" PATH="$FAKE_BIN:$PATH" TSM_LOGS_DIR="$LOGS" \
  bash "$TSM" log clean 2>&1); rc=$?
if [[ $rc -ne 0 ]] && [[ -f "$LOGS/work/0.0.log" && -f "$LOGS/play/0.0.log" ]]; then
  pass "empty session aborts (rc=$rc), logs preserved"
else
  fail "empty session guard" "rc=$rc msg='$out' — logs may have been deleted"
fi
rm -rf "$LOGS"

echo ""
echo "[ clean <session>: removes only that session ]"
LOGS="$(new_logs)"
env PATH="$FAKE_BIN:$PATH" TSM_LOGS_DIR="$LOGS" bash "$TSM" log clean work >/dev/null 2>&1
if [[ ! -e "$LOGS/work" && -f "$LOGS/play/0.0.log" ]]; then
  pass "cleaned 'work' only; 'play' preserved"
else
  fail "clean <session> scope" "work gone=$([[ ! -e "$LOGS/work" ]] && echo y || echo n), play kept=$([[ -f "$LOGS/play/0.0.log" ]] && echo y || echo n)"
fi
rm -rf "$LOGS"

echo ""
echo "[ clean --all: removes log files, leaves the dir standing ]"
LOGS="$(new_logs)"
env PATH="$FAKE_BIN:$PATH" TSM_LOGS_DIR="$LOGS" bash "$TSM" log clean --all >/dev/null 2>&1
remaining=$(find "$LOGS" -name '*.log' 2>/dev/null | wc -l | tr -d ' ')
if [[ -d "$LOGS" && "$remaining" == "0" ]]; then
  pass "all .log removed, logs dir intact"
else
  fail "clean --all" "dir exists=$([[ -d "$LOGS" ]] && echo y || echo n), remaining .log=$remaining"
fi
rm -rf "$LOGS"

echo ""
echo "────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
