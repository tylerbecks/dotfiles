#!/usr/bin/env bash

# Merges this repo's Claude Code settings into ~/.claude/settings.json, used by
# fresh.sh and linux.sh. settings.json is per-machine (rtk and work tooling add
# hooks to it), so only these keys are touched: the status line, the
# worktree-slot hook (claude/wt-hook.sh) and the guard hook (claude/guard.sh),
# each replaced rather than duplicated on re-runs.
#
# Everything here, and the skills and agents link_claude_config adds, belongs
# on every machine (personal, work and Linux boxes), so neither function checks
# is_work/is_personal. The guard hook sits alongside any PreToolUse hooks work
# tooling adds; a deny from either one wins.
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
    jq --arg wt "bash ~/dotfiles/claude/wt-hook.sh" \
        --arg guard "bash ~/dotfiles/claude/guard.sh" '
        def with_hook($event; $command; $entry):
            .hooks[$event] = ((.hooks[$event] // [])
                | map(select(any(.hooks[]?; .command == $command) | not))
                + [$entry]);
        def wt_entry: {"hooks": [{"type": "command", "command": $wt}]};
        .statusLine = {"type": "command", "command": "bash ~/dotfiles/claude/statusline.sh"}
        | with_hook("SessionStart"; $wt; wt_entry)
        | with_hook("UserPromptSubmit"; $wt; wt_entry)
        | with_hook("PreToolUse"; $guard; {
            "matcher": "Bash|Edit|Write|MultiEdit|NotebookEdit",
            "hooks": [{"type": "command", "command": $guard}]
        })' \
        "$settings" > "$tmp" && cat "$tmp" > "$settings"
    rm -f "$tmp"
}

# Links each skill in claude/skills and each agent in claude/agents into
# ~/.claude one entry at a time, so skills and agents that live only on this
# machine stay alongside them. Removes links to entries this repo no longer
# has, and leaves a real file or directory with the same name alone.
#
# Usage: source lib/claude-settings.sh, then link_claude_config
link_claude_config() {
    local repo
    repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    link_entries "${repo}/claude/skills" "${HOME}/.claude/skills"
    link_entries "${repo}/claude/agents" "${HOME}/.claude/agents"
}

link_entries() {
    local source_dir="$1" target_dir="$2" entry name
    mkdir -p "$target_dir"
    for entry in "$target_dir"/*; do
        if [ -L "$entry" ] && [ ! -e "$entry" ] && [[ "$(readlink "$entry")" == "$source_dir"/* ]]; then
            rm "$entry"
        fi
    done
    for entry in "$source_dir"/*; do
        [ -e "$entry" ] || continue
        name="$(basename "$entry")"
        if [ -e "$target_dir/$name" ] && [ ! -L "$target_dir/$name" ]; then
            warning "${target_dir/#"$HOME"/\~}/$name already exists and isn't a link; skipped it"
            continue
        fi
        ln -sfn "$entry" "$target_dir/$name"
    done
}
