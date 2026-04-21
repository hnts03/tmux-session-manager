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

- [ ] `tsm new [name]` — create and attach a new session from the CLI
- [ ] `tsm ls` — list all sessions without opening the picker
- [ ] `tsm kill [name]` — kill a session by name from the CLI
- [ ] Shell completion (bash / zsh / fish)

---

## License

[MIT](LICENSE)
