# tsm — tmux session manager

> A lightweight, fzf-powered tmux session manager for the terminal.

`tsm`은 fzf 기반의 인터랙티브 tmux 세션 매니저입니다.  
세션 목록을 퍼지 검색으로 탐색하고, 키 하나로 attach · create · delete · detach 를 처리합니다.

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
# GitHub Releases에서 최신 .deb 다운로드
wget https://github.com/hnts03/tmux-session-manager/releases/latest/download/tsm_0.1.0_all.deb
sudo dpkg -i tsm_0.1.0_all.deb
```

의존성이 없는 경우 자동 설치:

```sh
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

기본 설치 경로는 `/usr/local/bin`입니다. 변경하려면:

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
# 또는
INSTALL_DIR=~/.local/bin ./uninstall.sh
```

---

## Usage

### Interactive picker

```sh
tsm
```

tmux 세션 목록이 fzf picker로 열립니다.  
tmux 내부에서 실행하면 `switch-client`, 외부에서 실행하면 `attach-session`으로 동작합니다.

### Subcommands

```sh
tsm new [name]   # 새 세션 생성 후 attach (name 생략 시 이름 입력 프롬프트)
tsm ls           # 세션 목록 출력
tsm version      # 버전 출력
tsm help         # 도움말 출력
```

### Keybindings

| Key | Action |
|-----|--------|
| `↑` / `↓` or `k` / `j` | 목록 이동 |
| `Enter` / `Space` | 선택한 세션에 attach |
| `d` / `Backspace` | 선택한 세션 삭제 |
| `n` / `N` | 새 세션 생성 |
| `E` | 현재 tmux client detach |
| `q` / `ESC` | 종료 |

---

## Tips

**쉘 시작 시 자동 실행** (tmux 밖에 있을 때만):

```sh
# ~/.zshrc 또는 ~/.bashrc 에 추가
[[ -z "$TMUX" ]] && tsm
```

---

## License

[MIT](LICENSE)
