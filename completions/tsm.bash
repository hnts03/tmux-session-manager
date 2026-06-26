#!/usr/bin/env bash
# bash completion for tsm

_tsm_sessions() {
  tmux list-sessions -F "#{session_name}" 2>/dev/null
}

_tsm_saved_configs() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/tsm/sessions"
  find "$dir" -maxdepth 1 -name '*.yaml' -type f 2>/dev/null | sed 's|.*/||; s|\.yaml$||'
}

_tsm_user_templates() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/tsm/templates"
  find "$dir" -maxdepth 1 -name '*.yaml' -type f 2>/dev/null | sed 's|.*/||; s|\.yaml$||'
}

_tsm_completion() {
  local cur prev pprev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  pprev="${COMP_WORDS[COMP_CWORD-2]:-}"

  local subcommands="new ls kill rename config save restore log template clone doctor version help"

  case "$prev" in
    tsm)
      COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
      ;;
    kill)
      COMPREPLY=($(compgen -W "--all $(_tsm_sessions)" -- "$cur"))
      ;;
    rename|clone)
      COMPREPLY=($(compgen -W "$(_tsm_sessions)" -- "$cur"))
      ;;
    config)
      COMPREPLY=($(compgen -W "--read --edit --reload --tsm" -- "$cur"))
      ;;
    save)
      COMPREPLY=($(compgen -W "--list --delete $(_tsm_sessions)" -- "$cur"))
      ;;
    restore)
      COMPREPLY=($(compgen -W "--with-commands $(_tsm_saved_configs)" -- "$cur"))
      ;;
    --with-commands)
      # after --with-commands, complete saved configs
      if [[ "$pprev" == "restore" ]] || [[ "${COMP_WORDS[1]}" == "restore" ]]; then
        COMPREPLY=($(compgen -W "$(_tsm_saved_configs)" -- "$cur"))
      fi
      ;;
    --delete)
      if [[ "$pprev" == "save" ]] || [[ "${COMP_WORDS[1]}" == "save" ]]; then
        COMPREPLY=($(compgen -W "$(_tsm_saved_configs)" -- "$cur"))
      fi
      ;;
    log)
      COMPREPLY=($(compgen -W "start stop status list show tail grep clean help" -- "$cur"))
      ;;
    template)
      COMPREPLY=($(compgen -W "list apply save delete help" -- "$cur"))
      ;;
    apply)
      if [[ "${COMP_WORDS[1]}" == "template" ]]; then
        local builtins="builtin/simple builtin/split-h builtin/split-v builtin/main-h builtin/main-v"
        COMPREPLY=($(compgen -W "$builtins $(_tsm_user_templates)" -- "$cur"))
      fi
      ;;
    delete)
      if [[ "${COMP_WORDS[1]}" == "template" ]]; then
        COMPREPLY=($(compgen -W "$(_tsm_user_templates)" -- "$cur"))
      fi
      ;;
    show|tail|grep)
      COMPREPLY=($(compgen -W "--plain" -- "$cur"))
      ;;
    start)
      COMPREPLY=($(compgen -W "--timestamp --all" -- "$cur"))
      ;;
    clean)
      COMPREPLY=($(compgen -W "--all" -- "$cur"))
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}

complete -F _tsm_completion tsm
