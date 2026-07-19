#!/usr/bin/env bash
# Tests for config precedence: built-in defaults < config file < env vars.
# Uses `tsm __config` (resolved-config dump) and a fake tmux on PATH.
set -uo pipefail

PASS=0
FAIL=0
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TSM="$REPO_DIR/bin/tsm"
FAKE_BIN="$(mktemp -d)"
CFG_HOME="$(mktemp -d)"

cleanup() { rm -rf "$FAKE_BIN" "$CFG_HOME"; }
trap cleanup EXIT

cat > "$FAKE_BIN/tmux" <<'EOF'
#!/bin/sh
[ "$1" = "-V" ] && { echo "tmux 3.3"; exit 0; }
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

# dump <env-assignments...> -- : run `tsm __config` and echo the requested key's value
cfg_value() {
  local key="$1"; shift
  local -a envs=()
  while [[ "$1" != "--" ]]; do envs+=("$1"); shift; done
  shift
  env "${envs[@]}" PATH="$FAKE_BIN:$PATH" XDG_CONFIG_HOME="$CFG_HOME" \
    bash "$TSM" __config 2>/dev/null | awk -F= -v k="$key" '$1==k{print $2}'
}

check() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then pass "$desc"
  else fail "$desc" "expected='$expected' got='$actual'"; fi
}

CFG_FILE="$CFG_HOME/tsm/config.yaml"
mkdir -p "$CFG_HOME/tsm"

echo ""
echo "[ defaults (no config file, no env) ]"
rm -f "$CFG_FILE"
check "log_max_bytes default" "10485760" "$(cfg_value log_max_bytes -u TSM_LOG_MAX_BYTES -- )"
check "auto_log default true"  "true"     "$(cfg_value auto_log -u TSM_AUTO_LOG -- )"
check "popup default false"    "false"    "$(cfg_value popup -u TSM_POPUP -- )"
check "popup_size default 80%" "80%"      "$(cfg_value popup_size -u TSM_POPUP_SIZE -- )"

echo ""
echo "[ config file overrides defaults ]"
if command -v yq &>/dev/null; then
  printf 'log_max_bytes: 999\nauto_log: false\npopup: true\npopup_size: 60%%\n' > "$CFG_FILE"
  check "log_max_bytes from file" "999"  "$(cfg_value log_max_bytes -u TSM_LOG_MAX_BYTES -- )"
  check "auto_log from file"       "false" "$(cfg_value auto_log -u TSM_AUTO_LOG -- )"
  check "popup from file"          "true"  "$(cfg_value popup -u TSM_POPUP -- )"
  check "popup_size from file"     "60%"   "$(cfg_value popup_size -u TSM_POPUP_SIZE -- )"
else
  echo "  SKIP: yq not installed (config-file parsing needs yq)"
fi

echo ""
echo "[ env vars override the config file ]"
if command -v yq &>/dev/null; then
  # config file still says 999 / true from above
  check "TSM_LOG_MAX_BYTES beats file" "42"    "$(cfg_value log_max_bytes TSM_LOG_MAX_BYTES=42 -- )"
  check "TSM_POPUP=false beats file"   "false" "$(cfg_value popup TSM_POPUP=false -- )"
  check "TSM_POPUP_SIZE beats file"    "90%"   "$(cfg_value popup_size TSM_POPUP_SIZE=90% -- )"
else
  echo "  SKIP: yq not installed"
fi

echo ""
echo "────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
