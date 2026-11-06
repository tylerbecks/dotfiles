#!/usr/bin/env bash
# Claude Code hook for bin/wt worktree slots, registered for SessionStart and
# UserPromptSubmit by the setup scripts. Does nothing on machines without a
# ~/.config/wt/config, so it's safe everywhere.
#   SessionStart: tells the agent how to claim a slot (or which one it holds),
#     exports WT_SESSION for its shell, and runs `wt gc` in the background at
#     most once a day.
#   UserPromptSubmit: marks this session's slots as active so their leases
#     don't expire. Must print nothing: its output becomes prompt context.
# Must stay bash 3.2 compatible (macOS /bin/bash).

WT="$HOME/dotfiles/bin/wt"
"$WT" configured 2> /dev/null || exit 0

input=$(cat)
field() {
    if command -v jq &> /dev/null; then
        printf '%s' "$input" | jq -r --arg k "$1" '.[$k] // ""'
    else
        printf '%s' "$input" | sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p" | head -1
    fi
}
session=$(field session_id)
[ -n "$session" ] || exit 0

case "$(field hook_event_name)" in
    UserPromptSubmit)
        "$WT" touch --session "$session" &> /dev/null
        ;;
    SessionStart)
        [ -n "${CLAUDE_ENV_FILE:-}" ] && echo "export WT_SESSION=$session" >> "$CLAUDE_ENV_FILE"
        mkdir -p "$HOME/.local/state/wt"
        nohup "$WT" gc --if-due < /dev/null >> "$HOME/.local/state/wt/gc.log" 2>&1 &
        "$WT" context --session "$session" 2> /dev/null
        ;;
esac
exit 0
