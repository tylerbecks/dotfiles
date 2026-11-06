#!/usr/bin/env bash

# Merges this repo's Claude Code settings into ~/.claude/settings.json, used by
# fresh.sh and linux.sh. settings.json is per-machine (rtk and work tooling add
# hooks to it), so only these keys are touched: the status line, and the
# worktree-slot hook (claude/wt-hook.sh), which is replaced rather than
# duplicated on re-runs.
#
# Usage: source lib/claude-settings.sh, then merge_claude_settings

merge_claude_settings() {
    if ! command -v jq &> /dev/null; then
        warning "jq not found; skipped the Claude Code status line and hooks"
        return
    fi
    local settings="${HOME}/.claude/settings.json" tmp
    [ -s "$settings" ] || echo '{}' > "$settings"
    tmp=$(mktemp)
    jq --arg wt "bash ~/dotfiles/claude/wt-hook.sh" '
        def with_hook($event):
            .hooks[$event] = ((.hooks[$event] // [])
                | map(select(any(.hooks[]?; .command == $wt) | not))
                + [{"hooks": [{"type": "command", "command": $wt}]}]);
        .statusLine = {"type": "command", "command": "bash ~/dotfiles/claude/statusline.sh"}
        | with_hook("SessionStart")
        | with_hook("UserPromptSubmit")' \
        "$settings" > "$tmp" && cat "$tmp" > "$settings"
    rm -f "$tmp"
}
