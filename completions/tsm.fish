# fish completion for tsm

function __tsm_sessions
    tmux list-sessions -F "#{session_name}" 2>/dev/null
end

# disable file completion
complete -c tsm -f

# subcommands
complete -c tsm -n "not __fish_seen_subcommand_from new ls kill version help" -a new     -d "Create and attach a new session"
complete -c tsm -n "not __fish_seen_subcommand_from new ls kill version help" -a ls      -d "List all sessions"
complete -c tsm -n "not __fish_seen_subcommand_from new ls kill version help" -a kill    -d "Kill a session by name"
complete -c tsm -n "not __fish_seen_subcommand_from new ls kill version help" -a version -d "Show version"
complete -c tsm -n "not __fish_seen_subcommand_from new ls kill version help" -a help    -d "Show help"

# kill: complete with session names
complete -c tsm -n "__fish_seen_subcommand_from kill" -a "(__tsm_sessions)"
