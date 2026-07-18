# tsm — Agent & Contributor Guide

Guidance for anyone (human or AI agent) working on this repository.
`CLAUDE.md` is a symlink to this file, so Claude Code reads the same rules.
For machine-specific or personal notes that should NOT be shared, use
`CLAUDE.local.md` (gitignored).

---

## Working rules

- **All project files must be written in English** — code, comments, docs, commit
  messages, this guide. (Conversation with the maintainer may be in another language,
  but nothing that lands in the repo.)
- **Pause and ask the maintainer** instead of guessing when:
  - a design decision needs an opinion (UX flow, flag naming, edge-case behavior),
  - a change is destructive or hard to reverse,
  - a feature has multiple valid approaches with a non-obvious tradeoff,
  - an action needs a permission that has not been granted.
- Do not invent scope. Implement what was asked; record follow-up ideas in the
  README backlog rather than building them unprompted.
- Match the surrounding code's style: `set -euo pipefail`, `local` vars, `do_*`
  action functions, `[[ ... ]] && ...` guards. Keep everything in the single script.

---

## Project overview

`tsm` is a **single-file bash script**: `bin/tsm`. All logic lives there.

- **Runtime dependencies:** `tmux`, `fzf`. `yq` is required only for save/restore,
  templates, groups, and config-file reading.
- **Version** is defined in exactly one place: `VERSION="X.Y.Z"` near the top of
  `bin/tsm`. Nothing else hardcodes the version.
- Config precedence: built-in defaults → `~/.config/tsm/config.yaml` → env vars
  (`TSM_*`). Implemented via `_TSM_*` globals set at startup by `load_config` +
  `apply_env_overrides`.
- Paths: sessions in `~/.config/tsm/sessions/`, groups in `~/.config/tsm/groups/`,
  templates in `~/.config/tsm/templates/`, logs in `~/.local/share/tsm/logs/`.

---

## Development workflow

1. **Branch** off `main` (don't commit straight to `main` for non-trivial work).
2. **Edit** `bin/tsm` (and completions / docs as needed).
3. **Check syntax:** `bash -n bin/tsm`.
4. **Lint** (if available): `shellcheck bin/tsm`.
5. **Run the test suite:** `test/run_all.sh` (see Testing). Requires `tmux`, `fzf`, `yq`.
6. **Update docs** in the same change: `README.md` usage/roadmap, shell completions
   (`completions/tsm.bash`, `completions/_tsm`, `completions/tsm.fish`), and the
   Design decisions section below when behavior is non-obvious.
7. **Open a PR.** CI (`.github/workflows/ci.yml`) runs syntax + lint + the test suite
   on every push and PR. Keep it green.

When adding a user-facing subcommand, touch **all** of: dispatch in `bin/tsm`,
`usage()`, `README.md`, the three completion files, and a test in `test/`.

---

## Testing

Integration tests live in `test/*.sh` and are plain bash. They exercise the real
script against an **isolated tmux server** (`tmux -L <socket>`), with a `tmux`
wrapper placed early on `PATH` so the child `tsm` process talks to the same socket,
and `TSM_SESSIONS_DIR` / `TSM_LOGS_DIR` / `XDG_CONFIG_HOME` pointed at temp dirs.
This keeps tests hermetic — they never touch your real sessions or configs.

- Run everything: `test/run_all.sh`
- Run one file: `bash test/test_group.sh`
- A test file prints `Results: N passed, M failed` and exits non-zero on any failure.

Current suites:

| File | Covers |
|------|--------|
| `test/test_restore_all.sh` | `save --all` / `restore --all` lifecycle, partial-failure resilience |
| `test/test_group.sh`       | `group save/restore/list/delete` lifecycle, member isolation |
| `test/test_completion.sh`  | completion scripts load and expose expected subcommands |

**Add a test with every behavior change.** Model new tests on the isolated-socket
pattern in the existing files.

---

## Release procedure

Version is managed in **one place only**: `VERSION=` in `bin/tsm`. CI does the rest.

```bash
# 1. Bump VERSION in bin/tsm, then commit
git add bin/tsm
git commit -m "chore: bump version to vX.Y.Z"

# 2. Push tag — GitHub Actions takes over
git tag vX.Y.Z
git push origin main && git push origin vX.Y.Z
```

What `.github/workflows/release.yml` does automatically on a `v*` tag:
- builds the `.deb` package (from `packaging/debian/`),
- creates the GitHub Release and attaches `.deb` + `bin/tsm`,
- updates `Formula/tsm.rb` (version + SHA256) **onto the latest `main` tip** and
  pushes it back.

**Never do manually:** edit `Formula/tsm.rb` version/SHA, build the `.deb`, or change
the version in `Makefile`. Let CI own those.

---

## Backlog

See the **Backlog (deferred)** and **Future Works** sections in `README.md` for the
prioritized list of planned features. Work through them top to bottom unless the
maintainer specifies otherwise.

---

## Design decisions (recorded)

**Restore with commands (`--with-commands` flag)**
- `tsm restore` default: cwd only.
- `tsm restore --with-commands [name]`: also re-runs saved pane commands.
- Skip list (do NOT re-run): bash, zsh, sh, fish, dash, tmux, vim, nvim, top, htop, less.
  Full-screen apps are skipped: re-running them with no args is useless and their
  redraw collides with the restore TTY notification.
- Skip-list default is hardcoded; users override via `restore_skip_commands` in config.

**Session groups / workspaces (`tsm group`)**
- A group is a named set of sessions stored at `~/.config/tsm/groups/<name>.yaml`.
- `group save <name> [session...]` snapshots each member via `do_save --quiet` AND
  writes the manifest, so members are ordinary session configs — individually
  restorable too. No session args → fzf multi-select of running sessions (TAB).
- `group restore` mirrors `restore --all`: skips already-running members, reports counts.
- `group delete` removes only the manifest, never the member session configs.

**Restore log-path notice**
- On save, each pane records its `log_file` path in the yaml. On restore, that path
  is written directly to the pane's TTY (not via the shell) so history isn't polluted.

**Config file (`~/.config/tsm/config.yaml`)**
- Options: `log_max_bytes`, `sessions_dir`, `logs_dir`, `restore_skip_commands`, `auto_log`.
- Env vars always override the config file: `TSM_LOG_MAX_BYTES`, `TSM_SESSIONS_DIR`,
  `TSM_LOGS_DIR`, `TSM_AUTO_LOG`.
- `yq` is required to read the config; if it's absent and a config file exists, warn
  and fall back to defaults.
