#!/usr/bin/env bash

# Merges this repo's Claude Code settings into ~/.claude/settings.json, used by
# fresh.sh and linux.sh. settings.json is per-machine (rtk and work tooling add
# hooks to it), so only these keys are touched: the status line, the
# worktree-slot hook (claude/wt-hook.sh), the guard hook (claude/guard.sh) and
# the CLAUDE_GIT_ENV variables in .env, each replaced rather than duplicated on
# re-runs. Other .env variables stay.
#
# Everything here, and the skills and agents link_claude_config adds, belongs
# on every machine (personal, work and Linux boxes), so neither function checks
# is_work/is_personal. The guard hook sits alongside any PreToolUse hooks work
# tooling adds; a deny from either one wins.
#
# Usage: source lib/claude-settings.sh, then merge_claude_settings

# Environment for the commands Claude runs, not for your own terminal. An
# editor that waits (`code --wait`) never returns there, because nobody closes
# the tab, so the git command hangs. `true` exits at once: git keeps the
# message or to-do list it already has, or aborts a commit that has none.
# Claude Code sets GIT_EDITOR=true itself, but .gitconfig's sequence.editor
# beats that for `git rebase -i`, which hung until GIT_SEQUENCE_EDITOR was set.
# GIT_EDITOR is repeated in case Claude Code stops setting it.
CLAUDE_GIT_ENV='{"GIT_EDITOR": "true", "GIT_SEQUENCE_EDITOR": "true", "GIT_MERGE_AUTOEDIT": "no"}'

merge_claude_settings() {
    if ! command -v jq &> /dev/null; then
        warning "jq not found; skipped the Claude Code status line and hooks"
        return
    fi
    local settings="${HOME}/.claude/settings.json" tmp
    [ -s "$settings" ] || echo '{}' > "$settings"
    tmp=$(mktemp)
    jq --arg wt "bash ~/dotfiles/claude/wt-hook.sh" \
        --arg guard "bash ~/dotfiles/claude/guard.sh" \
        --argjson git_env "$CLAUDE_GIT_ENV" '
        def with_hook($event; $command; $entry):
            .hooks[$event] = ((.hooks[$event] // [])
                | map(select(any(.hooks[]?; .command == $command) | not))
                + [$entry]);
        def wt_entry: {"hooks": [{"type": "command", "command": $wt}]};
        .statusLine = {"type": "command", "command": "bash ~/dotfiles/claude/statusline.sh"}
        | .env = ((.env // {}) + $git_env)
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

# Checks what merge_claude_settings and link_claude_config set up, without
# changing anything. Returns 1 if something is missing.
# Usage: source lib/claude-settings.sh, then check_claude_config
check_claude_config() {
    local settings="${HOME}/.claude/settings.json" repo status=0 entry name
    repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    if ! command -v jq &> /dev/null; then
        warning "jq not found; skipped checking ~/.claude/settings.json"
    elif [ ! -s "$settings" ]; then
        error "~/.claude/settings.json is missing"
        status=1
    else
        if ! jq -e '.statusLine.command == "bash ~/dotfiles/claude/statusline.sh"' "$settings" &> /dev/null; then
            error "The status line isn't set in ~/.claude/settings.json"
            status=1
        fi
        local event command
        for event in "SessionStart:bash ~/dotfiles/claude/wt-hook.sh" \
            "UserPromptSubmit:bash ~/dotfiles/claude/wt-hook.sh" \
            "PreToolUse:bash ~/dotfiles/claude/guard.sh"; do
            command="${event#*:}"
            event="${event%%:*}"
            if ! jq -e --arg event "$event" --arg command "$command" \
                'any(.hooks[$event][]?.hooks[]?; .command == $command)' "$settings" &> /dev/null; then
                error "The ${event} hook (${command}) is missing from ~/.claude/settings.json"
                status=1
            fi
        done
        if ! jq -e --argjson git_env "$CLAUDE_GIT_ENV" \
            '(.env // {}) as $env | all($git_env | to_entries[]; $env[.key] == .value)' "$settings" &> /dev/null; then
            error "The git editor variables (GIT_EDITOR and friends) aren't in ~/.claude/settings.json's env"
            status=1
        fi
        [ "$status" -eq 0 ] && success "Status line, hooks and git editor variables are in ~/.claude/settings.json"
    fi

    local missing=0
    for entry in "${repo}/claude/skills"/* "${repo}/claude/agents"/*; do
        [ -e "$entry" ] || continue
        name="$(basename "$(dirname "$entry")")/$(basename "$entry")"
        if [ "$(readlink "${HOME}/.claude/${name}")" != "$entry" ]; then
            error "~/.claude/${name} isn't linked to this repo"
            missing=1
        fi
    done
    if [ "$missing" -eq 0 ]; then
        success "Skills and agents are linked into ~/.claude"
    else
        status=1
    fi
    return "$status"
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
