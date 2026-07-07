# tsm — tmux session manager

> A lightweight, fzf-powered tmux session manager for the terminal.

`tsm` lets you list, switch, create, and delete tmux sessions from an interactive fuzzy-search picker — no more typing session names by hand.

---

## Preview

```
$ tsm

  work                             │   1: editor  (2 panes)
  dotfiles                         │   2: server  (1 pane)
  [+] Create new session           │
──────────────────────────────────────────────────────
  tmux session > _
  ↑↓/jk:move  ↵:attach  d:delete  n:new  E:detach  q/ESC:quit
  r:rename  s:save  R:restore-saved
```

---

## Requirements

- [tmux](https://github.com/tmux/tmux) ≥ 2.8
- [fzf](https://github.com/junegunn/fzf)

---

## Installation

### Homebrew (macOS / Linux)

```sh
brew tap hnts03/tsm
brew install tsm
```

### apt (Debian / Ubuntu)

```sh
wget $(curl -s https://api.github.com/repos/hnts03/tmux-session-manager/releases/latest \
  | grep "browser_download_url.*\.deb" | cut -d'"' -f4)
sudo apt install ./tsm_*.deb
```

### Manual (curl)

```sh
curl -fsSL https://raw.githubusercontent.com/hnts03/tmux-session-manager/main/install.sh | bash
```

### Manual (git clone)

```sh
git clone https://github.com/hnts03/tmux-session-manager.git
cd tmux-session-manager
./install.sh
```

The default install path is `/usr/local/bin`. To change it:

```sh
INSTALL_DIR=~/.local/bin ./install.sh
```

---

## Uninstall

### Homebrew

```sh
brew uninstall tsm
```

### apt

```sh
sudo apt remove tsm
```

### Manual

```sh
./uninstall.sh
# or
INSTALL_DIR=~/.local/bin ./uninstall.sh
```

---

## Usage

```sh
tsm
```

Opens an fzf picker with all tmux sessions. Inside tmux it runs `switch-client`; outside it runs `attach-session`.

### Subcommands

```sh
tsm new [name]      # create and attach a new session (prompts if name omitted)
tsm ls              # list all sessions
tsm kill [name]     # kill a session (opens picker if name omitted)
tsm kill --all      # kill multiple sessions (fzf multi-select, TAB to select)
tsm rename <old> <new>  # rename a session
tsm config          # read tmux config (default: --read)
tsm config --edit   # edit tmux config, prompts to reload after saving
tsm config --reload # reload tmux config (must be inside tmux)
tsm config --tsm    # edit tsm's own config (~/.config/tsm/config.yaml)
tsm save [name]     # save session to ~/.config/tsm/sessions/<name>.yaml
                    # (uses current attached session if name omitted)
                    # add description: "..." to the YAML to show in picker preview
tsm save --list     # list saved configs with metadata (date, windows, panes)
tsm save --delete [name]  # delete a saved config (fzf picker if name omitted)
tsm restore [name]                 # restore a saved session (layout only)
tsm restore --with-commands [name] # restore layout + re-run saved commands
                                   # (skips shells: bash zsh sh fish dash tmux)
tsm log grep <pattern> [target]    # search within log file (default: current pane)
tsm log grep --plain <pattern>     # strip ANSI escapes before matching
tsm log grep --all <pattern>       # search all log files; prefix each match with session:window.pane
tsm clone [src] [new-name]  # duplicate a live session's window/pane layout into a new session
tsm doctor          # check dependencies, validate config, show log/session disk usage
tsm version         # show version
tsm help            # show help
```

### Keybindings

| Key | Action |
|-----|--------|
| `↑` / `↓` or `k` / `j` | Navigate |
| `1`–`9` | Attach to nth session instantly (no Enter needed) |
| `Enter` / `Space` | Attach to selected session |
| `d` | Delete selected session (confirmation prompt) |
| `n` / `N` | Create new session |
| `r` | Rename selected session |
| `s` | Save selected session layout |
| `S` | Save all running sessions (confirmation prompt) |
| `R` | Open restore menu (shows saved date, window/pane count, running status) |
| `W` | *(inside restore menu)* Restore layout + re-run saved commands |
| `l` | Toggle pane logging for the selected session's active pane |
| `t` | Create new session from a template (opens template picker) |
| `E` | Detach current tmux client |
| `<` / `>` | Cycle through panes of the previewed session (preview auto-refreshes every second) |
| `[` / `]` | Shrink / grow the preview pane (30% → 50% → 70%) |
| `q` / `ESC` | Quit |

---

## Configuration

Create `~/.config/tsm/config.yaml` to set persistent defaults (requires `yq`):

```yaml
log_max_bytes: 10485760          # 10 MB (default)
sessions_dir: ~/.config/tsm/sessions
logs_dir: ~/.local/share/tsm/logs
auto_log: true                   # auto-start logging when tsm creates a new session
restore_skip_commands:           # commands NOT re-run by --with-commands
  - bash
  - zsh
  - sh
  - fish
  - dash
  - tmux
```

Environment variables always override config file values: `TSM_LOG_MAX_BYTES`, `TSM_SESSIONS_DIR`, `TSM_LOGS_DIR`.

---

## Tips

**Auto-launch when outside tmux** — add to `~/.zshrc` or `~/.bashrc`:

```sh
[[ -z "$TMUX" ]] && tsm
```

---

## Roadmap

- [x] `tsm new [name]` — create and attach a new session from the CLI
- [x] `tsm ls` — list all sessions without opening the picker
- [x] `tsm kill [name]` / `tsm kill --all` — kill one or multiple sessions
- [x] `tsm rename <old> <new>` — rename a session from the CLI
- [x] `tsm config` — read / edit / reload tmux config
- [x] `tsm save [name]` / `tsm save --list` / `tsm save --delete` — save and manage session layouts
- [x] `tsm restore [name]` / `tsm restore --with-commands` — restore a saved session (layout-only or with commands)
- [x] `tsm log start/stop/status/list/show/tail/clean` — opt-in pane output logging with size cap & rotation
- [x] Shell completions (bash, zsh, fish)
- [x] Picker: `r` rename, `s` save, `R` restore-saved, fzf preview pane showing windows/panes
- [x] `~/.config/tsm/config.yaml` — persistent config file (log path, max bytes, skip commands, etc.)
- [x] `tsm new` name conflict handling — offer to attach if session already exists

### Backlog (deferred)

- [ ] `tsm restore --overwrite <name>` — kill all windows/panes of a running session and rebuild from a saved config. Deferred due to destructive nature; needs confirmation flow.
- [ ] `tsm log auto on/off` — automatic logging via tmux hooks injected into the user's config. Deferred until manual mode + size cap are battle-tested.

### Future Works

**Config & UX polish**
- [x] `tsm config --tsm` — open tsm's own config file (`~/.config/tsm/config.yaml`) in editor
- [x] `tsm save --update` — prompt before overwriting an existing saved config
- [x] `tsm save --list` — show indicator when a saved config's session is currently running

**Picker improvements**
- [x] `tsm restore` picker: fzf preview pane showing saved windows/pane layout
- [x] `l` key in picker — toggle pane logging for the selected session's active pane

**New subcommands**
- [x] `tsm log grep <pattern> [target]` — search within log files
- [x] `tsm log start --timestamp` — prepend timestamps to each logged line

**Robustness**
- [x] `tsm restore` layout fallback — apply `even-horizontal` if saved layout string fails (terminal size mismatch)

---

### Next Future Works

**1. Session templates**
- [x] `tsm template` subcommand — manage predefined session layouts independent of live sessions
- [x] fzf picker for template selection with preview of windows/panes layout
- [x] Built-in starter templates (e.g. `default`, `dev`, `monitoring`)
- [x] `tsm template save <name>` from current session, `tsm template apply <name>` to spawn a new session

**2. Restore UX**
- [x] Dedicated restore menu — `R` key in main picker opens a full restore UI (not just a plain fzf list)
- [x] Restore picker shows running indicator, last-saved date, window/pane count in preview

**3. Picker numeric shortcuts**
- [x] Press `1`–`9` in the main fzf picker to instantly attach to the nth session (no Enter needed)

**4. Session info in picker**
- [x] Show uptime, window count, pane count alongside session name in the picker list
- [x] Optional per-session description field stored in saved config, shown in preview

**5. Log improvements**
- [x] Auto-logging on session create (default: on, configurable via `auto_log` in `config.yaml`)
- [x] `tsm log grep --all <pattern>` — search across all sessions/windows/panes at once, prefix each match with `session:window.pane`

**6. tsm doctor**
- [x] `tsm doctor` — check dependency versions, validate config file, summarise log directory disk usage

**7. tsm clone**
- [x] `tsm clone [source-session] [new-name]` — duplicate a live session's window/pane layout into a new session

---

## License

[MIT](LICENSE)
