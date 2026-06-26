# fish completion for tsm

function __tsm_sessions
    tmux list-sessions -F "#{session_name}" 2>/dev/null
end

function __tsm_saved_configs
    set -l dir (test -n "$XDG_CONFIG_HOME"; and echo "$XDG_CONFIG_HOME"; or echo "$HOME/.config")/tsm/sessions
    find "$dir" -maxdepth 1 -name '*.yaml' -type f 2>/dev/null | sed 's|.*/||; s|\.yaml$||'
end

function __tsm_user_templates
    set -l dir (test -n "$XDG_CONFIG_HOME"; and echo "$XDG_CONFIG_HOME"; or echo "$HOME/.config")/tsm/templates
    find "$dir" -maxdepth 1 -name '*.yaml' -type f 2>/dev/null | sed 's|.*/||; s|\.yaml$||'
end

set -l subcommands new ls kill rename config save restore log template version help

# disable file completion
complete -c tsm -f

# subcommands
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a new     -d "Create and attach a new session"
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a ls      -d "List all sessions"
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a kill    -d "Kill a session"
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a rename  -d "Rename a session"
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a config  -d "Read/edit/reload tmux config"
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a save    -d "Save session layout"
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a restore -d "Restore a saved session"
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a log      -d "Pane output logging"
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a template -d "Manage session templates"
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a version  -d "Show version"
complete -c tsm -n "not __fish_seen_subcommand_from $subcommands" -a help    -d "Show help"

# kill: session names + --all
complete -c tsm -n "__fish_seen_subcommand_from kill" -a "(__tsm_sessions)"
complete -c tsm -n "__fish_seen_subcommand_from kill" -l all -d "Kill multiple sessions (fzf multi-select)"

# rename: session names for first arg
complete -c tsm -n "__fish_seen_subcommand_from rename" -a "(__tsm_sessions)"

# config: flags
complete -c tsm -n "__fish_seen_subcommand_from config" -l read   -d "Read tmux config (default)"
complete -c tsm -n "__fish_seen_subcommand_from config" -l edit   -d "Edit tmux config"
complete -c tsm -n "__fish_seen_subcommand_from config" -l reload -d "Reload tmux config"
complete -c tsm -n "__fish_seen_subcommand_from config" -l tsm    -d "Edit tsm config"

# save: session names + flags
complete -c tsm -n "__fish_seen_subcommand_from save" -a "(__tsm_sessions)"
complete -c tsm -n "__fish_seen_subcommand_from save" -l list   -d "List saved configs"
complete -c tsm -n "__fish_seen_subcommand_from save" -l delete -d "Delete a saved config"

# restore: saved config names + --with-commands
complete -c tsm -n "__fish_seen_subcommand_from restore" -a "(__tsm_saved_configs)"
complete -c tsm -n "__fish_seen_subcommand_from restore" -l with-commands -d "Re-run saved commands on restore"

# log: actions
set -l log_actions start stop status list show tail grep clean help
complete -c tsm -n "__fish_seen_subcommand_from log; and not __fish_seen_subcommand_from $log_actions" -a start  -d "Start logging pane output"
complete -c tsm -n "__fish_seen_subcommand_from log; and __fish_seen_subcommand_from start" -l timestamp -d "Prepend timestamps to each logged line"
complete -c tsm -n "__fish_seen_subcommand_from log; and not __fish_seen_subcommand_from $log_actions" -a stop   -d "Stop logging"
complete -c tsm -n "__fish_seen_subcommand_from log; and not __fish_seen_subcommand_from $log_actions" -a status -d "Show panes being logged"
complete -c tsm -n "__fish_seen_subcommand_from log; and not __fish_seen_subcommand_from $log_actions" -a list   -d "List log files"
complete -c tsm -n "__fish_seen_subcommand_from log; and not __fish_seen_subcommand_from $log_actions" -a show   -d "View log via pager"
complete -c tsm -n "__fish_seen_subcommand_from log; and not __fish_seen_subcommand_from $log_actions" -a tail   -d "Follow log in real time"
complete -c tsm -n "__fish_seen_subcommand_from log; and not __fish_seen_subcommand_from $log_actions" -a grep   -d "Search within log file"
complete -c tsm -n "__fish_seen_subcommand_from log; and not __fish_seen_subcommand_from $log_actions" -a clean  -d "Delete log files"
complete -c tsm -n "__fish_seen_subcommand_from log; and not __fish_seen_subcommand_from $log_actions" -a help   -d "Show log help"

# log show/tail/grep: --plain flag
complete -c tsm -n "__fish_seen_subcommand_from log; and __fish_seen_subcommand_from show tail grep" -l plain -d "Strip ANSI escapes"

# template: sub-actions
set -l template_actions list apply save delete help
complete -c tsm -n "__fish_seen_subcommand_from template; and not __fish_seen_subcommand_from $template_actions" -a list   -d "List all templates"
complete -c tsm -n "__fish_seen_subcommand_from template; and not __fish_seen_subcommand_from $template_actions" -a apply  -d "Create session from template"
complete -c tsm -n "__fish_seen_subcommand_from template; and not __fish_seen_subcommand_from $template_actions" -a save   -d "Save current session as template"
complete -c tsm -n "__fish_seen_subcommand_from template; and not __fish_seen_subcommand_from $template_actions" -a delete -d "Delete a user template"
complete -c tsm -n "__fish_seen_subcommand_from template; and not __fish_seen_subcommand_from $template_actions" -a help   -d "Show template help"

# template apply: built-in names + user templates
complete -c tsm -n "__fish_seen_subcommand_from template; and __fish_seen_subcommand_from apply" \
    -a "builtin/simple builtin/split-h builtin/split-v builtin/main-h builtin/main-v" -d "Built-in template"
complete -c tsm -n "__fish_seen_subcommand_from template; and __fish_seen_subcommand_from apply" \
    -a "(__tsm_user_templates)"

# template delete: user templates only
complete -c tsm -n "__fish_seen_subcommand_from template; and __fish_seen_subcommand_from delete" \
    -a "(__tsm_user_templates)"
