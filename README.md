# tsm — tmux session manager

> A lightweight, fzf-powered tmux session manager for the terminal.

`tsm` lets you list, switch, create, and delete tmux sessions from an interactive fuzzy-search picker — no more typing session names by hand.

---

## Preview

```
$ tsm

  work
  dotfiles
  [+] Create new session
──────────────────────────────────────────────────────
  tmux session > _
  ↑↓/jk:move  ↵:attach  d/⌫:delete  n:new  E:detach  q/ESC:quit
```

---

## Requirements

- [tmux](https://github.com/tmux/tmux) ≥ 2.x
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
wget https://github.com/hnts03/tmux-session-manager/releases/latest/download/tsm_0.1.0_all.deb
sudo apt install ./tsm_0.1.0_all.deb
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
tsm config          # read tmux config (default: --read)
tsm config --edit   # edit tmux config, prompts to reload after saving
tsm config --reload # reload tmux config (must be inside tmux)
tsm save [name]     # save session to ~/.config/tsm/sessions/<name>.yaml
                    # (uses current attached session if name omitted)
tsm restore [name]  # restore a saved session as a new session
                    # (opens picker if name omitted)
tsm version         # show version
tsm help            # show help
```

### Keybindings

| Key | Action |
|-----|--------|
| `↑` / `↓` or `k` / `j` | Navigate |
| `Enter` / `Space` | Attach to selected session |
| `d` / `Backspace` | Delete selected session |
| `n` / `N` | Create new session |
| `E` | Detach current tmux client |
| `q` / `ESC` | Quit |

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
- [x] `tsm kill [name]` — kill a session by name from the CLI
- [x] Shell completion (bash / zsh)
- [ ] Shell completion (fish)
- [x] `tsm config` — read / edit / reload tmux config
- [x] `tsm save [name]` — save current session's window/pane layout, cwd, and current command to `~/.config/tsm/sessions/<name>.yaml`
- [x] `tsm restore [name]` — restore a saved config as a **new** session (fzf picker if name omitted)
- [ ] Continuous pane output logging — pipe each pane's output to a log file for later inspection / restoration

### Backlog (deferred)

- [ ] `tsm restore --overwrite <name>` — kill all windows/panes of a running session and rebuild from a saved config. Deferred due to destructive nature; needs confirmation flow.

---

## License

[MIT](LICENSE)
