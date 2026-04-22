#!/usr/bin/env bash
# bash completion for tsm

_tsm_sessions() {
  tmux list-sessions -F "#{session_name}" 2>/dev/null
}

_tsm_completion() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local subcommands="new ls kill version help"

  case "$prev" in
    tsm)
      COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
      ;;
    kill)
      COMPREPLY=($(compgen -W "$(_tsm_sessions)" -- "$cur"))
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}

complete -F _tsm_completion tsm
