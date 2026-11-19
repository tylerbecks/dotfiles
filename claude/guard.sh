#!/usr/bin/env bash

# Claude Code PreToolUse hook, merged into ~/.claude/settings.json by the setup
# scripts. Denies commands that destroy work or history (recursive force
# deletes, force pushes, hard resets) and edits to .env files or anything
# inside .git/. `git push --force-with-lease` stays allowed.
#
# Test: bash claude/guard.test.sh

set -uo pipefail

# Fail open without jq; the settings merge needs jq too, so this only happens
# if jq was removed after setup.
command -v jq &> /dev/null || exit 0

input=$(cat)

main() {
    local tool reason
    tool=$(jq -r '.tool_name // empty' <<< "$input")
    case "$tool" in
        Bash)
            reason=$(command_reason "$(jq -r '.tool_input.command // empty' <<< "$input")") &&
                deny "Blocked: the command matches '$reason'. If it's really needed, ask the user to run it themselves."
            ;;
        Edit | Write | MultiEdit | NotebookEdit)
            reason=$(file_reason "$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<< "$input")") &&
                deny "Blocked: editing $reason files is not allowed. Ask the user to make this change."
            ;;
    esac
    exit 0
}

# Short flags are matched as bundles (-rf, -fv, -fu), so extra letters don't
# slip past. A command name may follow a path (/bin/rm), a backslash (\rm) or a
# subshell opener, not just a separator. Labels line up with the regexes by
# index.
START='(^|[;&|[:space:]()`/\\])'
COMMAND_REGEXES=(
    "${START}"'rm[[:space:]]+-[[:alnum:]]*([rR][[:alnum:]]*[fF]|[fF][[:alnum:]]*[rR])'
    "${START}"'rm[[:space:]]+([^;&|]*[[:space:]])?(-[[:alnum:]]*[rR][[:alnum:]]*|--recursive)([[:space:]][^;&|]*)*[[:space:]](-[[:alnum:]]*[fF][[:alnum:]]*|--force)([[:space:]]|$)'
    "${START}"'rm[[:space:]]+([^;&|]*[[:space:]])?(-[[:alnum:]]*[fF][[:alnum:]]*|--force)([[:space:]][^;&|]*)*[[:space:]](-[[:alnum:]]*[rR][[:alnum:]]*|--recursive)([[:space:]]|$)'
    "${START}"'git[[:space:]]+([^;&|]*[[:space:]])?push([[:space:]][^;&|]*)*[[:space:]](-[[:alnum:]]*f[[:alnum:]]*|--force)([[:space:]]|$)'
    "${START}"'git[[:space:]]+([^;&|]*[[:space:]])?push([[:space:]][^;&|]*)*[[:space:]]--mirror([[:space:]]|$)'
    "${START}"'git[[:space:]]+([^;&|]*[[:space:]])?push([[:space:]][^;&|]*)*[[:space:]][+][^[:space:]]'
    "${START}"'git[[:space:]]+([^;&|]*[[:space:]])?reset([[:space:]][^;&|]*)*[[:space:]]--hard([[:space:]]|$)'
)
COMMAND_LABELS=(
    "rm -rf"
    "rm -r ... -f"
    "rm -f ... -r"
    "git push --force"
    "git push --mirror"
    "git push +refspec"
    "git reset --hard"
)

# Quoted strings are checked as commands of their own and replaced by a
# placeholder in the outer command, so `git commit -m 'fix push -f'` passes
# while `bash -c "rm -rf x"` is still caught. Newlines separate commands, so a
# flag on the next line can't complete a match.
command_reason() {
    local rest="${1//$'\n'/;}" quoted segment
    local segments=()
    while [[ "$rest" =~ (\"[^\"]*\"|\'[^\']*\') ]]; do
        quoted="${BASH_REMATCH[1]}"
        segments+=("${quoted:1:${#quoted}-2}")
        rest="${rest/"$quoted"/Q}"
    done
    segments+=("$rest")
    for segment in "${segments[@]}"; do
        segment_reason "$segment" && return 0
    done
    return 1
}

segment_reason() {
    local index
    for index in "${!COMMAND_REGEXES[@]}"; do
        if [[ "$1" =~ ${COMMAND_REGEXES[$index]} ]]; then
            echo "${COMMAND_LABELS[$index]}"
            return 0
        fi
    done
    return 1
}

file_reason() {
    case "$1" in
        *.env.example | *.env.sample | *.env.template) return 1 ;;
        .env | .env.* | */.env | */.env.*) echo ".env" ;;
        .git/* | */.git/*) echo ".git/" ;;
        *) return 1 ;;
    esac
}

deny() {
    jq -n --arg reason "$1" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
        }
    }'
    exit 0
}

main
