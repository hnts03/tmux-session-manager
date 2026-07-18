#!/usr/bin/env bash
# Unit/integration tests for popup-mode decision logic (tsm __popup_check).
# Uses a fake `tmux` on PATH that reports a chosen version via `tmux -V`, and
# controls TMUX / TSM_IN_POPUP explicitly so the result never depends on whether
# the test runner itself happens to be inside tmux.
set -uo pipefail

PASS=0
FAIL=0
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TSM="$REPO_DIR/bin/tsm"
FAKE_BIN="$(mktemp -d)"
CFG_HOME="$(mktemp -d)"   # isolate load_config from the real ~/.config/tsm

cleanup() { rm -rf "$FAKE_BIN" "$CFG_HOME"; }
trap cleanup EXIT

# Fake tmux: answer `-V` with $FAKE_TMUX_VERSION, ignore everything else.
cat > "$FAKE_BIN/tmux" <<'EOF'
#!/bin/sh
if [ "$1" = "-V" ]; then echo "tmux ${FAKE_TMUX_VERSION:-3.3}"; exit 0; fi
exit 0
EOF
chmod +x "$FAKE_BIN/tmux"

# fzf must exist for check_deps, but __popup_check never invokes it.
cat > "$FAKE_BIN/fzf" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$FAKE_BIN/fzf"

pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1"; echo "        $2"; (( FAIL++ )) || true; }

# check <desc> <expected> <env-assignments...> -- <tsm args...>
# Runs: <env> tsm __popup_check <args>  with the fake bin on PATH and isolated config.
check() {
  local desc="$1" expected="$2"; shift 2
  local -a envs=()
  while [[ "$1" != "--" ]]; do envs+=("$1"); shift; done
  shift  # drop --
  local actual
  actual=$(env "${envs[@]}" PATH="$FAKE_BIN:$PATH" XDG_CONFIG_HOME="$CFG_HOME" \
    bash "$TSM" __popup_check "$@" 2>/dev/null)
  if [[ "$actual" == "$expected" ]]; then pass "$desc"
  else fail "$desc" "expected='$expected' got='$actual'"; fi
}

echo ""
echo "[ version gate — inside tmux, --popup ]"
check "tmux 2.8  → inline" inline TMUX=fake FAKE_TMUX_VERSION=2.8  -- force-on
check "tmux 3.1a → inline" inline TMUX=fake FAKE_TMUX_VERSION=3.1a -- force-on
check "tmux 3.2  → popup"  popup  TMUX=fake FAKE_TMUX_VERSION=3.2  -- force-on
check "tmux 3.2a → popup"  popup  TMUX=fake FAKE_TMUX_VERSION=3.2a -- force-on
check "tmux 3.3  → popup"  popup  TMUX=fake FAKE_TMUX_VERSION=3.3  -- force-on

echo ""
echo "[ guards (tmux 3.3) ]"
check "outside tmux + force-on → inline"        inline -u TMUX FAKE_TMUX_VERSION=3.3 -- force-on
check "TSM_IN_POPUP=1 + force-on → inline"       inline TMUX=fake TSM_IN_POPUP=1 FAKE_TMUX_VERSION=3.3 -- force-on
check "force-off beats TSM_POPUP=true → inline"  inline TMUX=fake TSM_POPUP=true FAKE_TMUX_VERSION=3.3 -- force-off

echo ""
echo "[ config / env driven (no explicit override) ]"
check "TSM_POPUP=true → popup"   popup  TMUX=fake TSM_POPUP=true  FAKE_TMUX_VERSION=3.3 -- ''
check "TSM_POPUP=false → inline" inline TMUX=fake TSM_POPUP=false FAKE_TMUX_VERSION=3.3 -- ''
check "default (unset) → inline" inline TMUX=fake FAKE_TMUX_VERSION=3.3 -- ''

echo ""
echo "[ config file via yq ]"
if command -v yq &>/dev/null; then
  mkdir -p "$CFG_HOME/tsm"
  printf 'popup: true\n' > "$CFG_HOME/tsm/config.yaml"
  check "config popup: true → popup" popup TMUX=fake FAKE_TMUX_VERSION=3.3 -- ''
  printf 'popup: false\n' > "$CFG_HOME/tsm/config.yaml"
  check "config popup: false → inline" inline TMUX=fake FAKE_TMUX_VERSION=3.3 -- ''
  rm -f "$CFG_HOME/tsm/config.yaml"
else
  echo "  SKIP: yq not installed"
fi

echo ""
echo "────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
