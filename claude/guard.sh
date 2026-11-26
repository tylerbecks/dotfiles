#!/usr/bin/env bash

# Claude Code PreToolUse hook, merged into ~/.claude/settings.json by the setup
# scripts. Denies commands that destroy work or history (recursive force
# deletes, force pushes, hard resets), commands that skip the repo's git hooks
# (--no-verify, git commit -n), and edits to .env files or anything inside
# .git/. `git push --force-with-lease` stays allowed.
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
            reason=$(command_reason "$(jq -r '.tool_input.command // empty' <<< "$input")") || exit 0
            case "$reason" in
                "git --no-verify" | "git commit -n")
                    deny "Blocked: the command matches '$reason', which skips the repo's git hooks. Fix what the hook reports and run the command without it, or ask the user for help."
                    ;;
                *)
                    deny "Blocked: the command matches '$reason'. If it's really needed, ask the user to run it themselves."
                    ;;
            esac
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
# After a flag: whitespace, the end, or a shell separator (--no-verify; echo,
# -f&& ..., (git push --force)), so a chained command can't hide the flag.
END='([;&|()`[:space:]]|$)'
COMMAND_REGEXES=(
    "${START}"'rm[[:space:]]+-[[:alnum:]]*([rR][[:alnum:]]*[fF]|[fF][[:alnum:]]*[rR])'
    "${START}"'rm[[:space:]]+([^;&|]*[[:space:]])?(-[[:alnum:]]*[rR][[:alnum:]]*|--recursive)([[:space:]][^;&|]*)*[[:space:]](-[[:alnum:]]*[fF][[:alnum:]]*|--force)'"${END}"
    "${START}"'rm[[:space:]]+([^;&|]*[[:space:]])?(-[[:alnum:]]*[fF][[:alnum:]]*|--force)([[:space:]][^;&|]*)*[[:space:]](-[[:alnum:]]*[rR][[:alnum:]]*|--recursive)'"${END}"
    "${START}"'git[[:space:]]+([^;&|]*[[:space:]])?push([[:space:]][^;&|]*)*[[:space:]](-[[:alnum:]]*f[[:alnum:]]*|--force)'"${END}"
    "${START}"'git[[:space:]]+([^;&|]*[[:space:]])?push([[:space:]][^;&|]*)*[[:space:]]--mirror'"${END}"
    "${START}"'git[[:space:]]+([^;&|]*[[:space:]])?push([[:space:]][^;&|]*)*[[:space:]][+][^[:space:]]'
    "${START}"'git[[:space:]]+([^;&|]*[[:space:]])?reset([[:space:]][^;&|]*)*[[:space:]]--hard'"${END}"
    # Any git subcommand: commit, push, merge, rebase and am all take it
    "${START}"'git[[:space:]]+([^;&|]*[[:space:]])?--no-verify'"${END}"
    # -n is --no-verify only for commit (push -n is a dry run). A bundle is
    # commit's value-free short options (a e i o p q s v z, from git commit -h),
    # then optionally one that takes a value (F m c C t S U u),
    # given next (-anm "msg") or attached (-nmmsg, -nuall). An n after a
    # value-taking option is part of the value, so -mnope and -uno pass.
    "${START}"'git[[:space:]]+([^;&|]*[[:space:]])?commit([[:space:]][^;&|]*)*[[:space:]]-[aeiopqsvz]*n[aeiopqsvz]*([mFCctSUu][^[:space:]]*)?'"${END}"
)
COMMAND_LABELS=(
    "rm -rf"
    "rm -r ... -f"
    "rm -f ... -r"
    "git push --force"
    "git push --mirror"
    "git push +refspec"
    "git reset --hard"
    "git --no-verify"
    "git commit -n"
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
