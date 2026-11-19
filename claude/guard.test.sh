#!/usr/bin/env bash

# Tests for claude/guard.sh. Run: bash claude/guard.test.sh

set -uo pipefail

GUARD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/guard.sh"
failures=0

check() {
    local expected="$1" tool="$2" field="$3" value="$4" output actual
    output=$(jq -n --arg tool "$tool" --arg field "$field" --arg value "$value" \
        '{tool_name: $tool, tool_input: {($field): $value}}' | bash "$GUARD")
    if [[ "$(jq -r '.hookSpecificOutput.permissionDecision // empty' <<< "$output" 2> /dev/null)" == "deny" ]]; then
        actual=deny
    else
        actual=allow
    fi
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: expected $expected, got $actual: $tool $value"
        failures=$((failures + 1))
    fi
}

deny_command() { check deny Bash command "$1"; }
allow_command() { check allow Bash command "$1"; }
deny_file() { check deny Edit file_path "$1"; }
allow_file() { check allow Edit file_path "$1"; }

deny_command 'rm -rf build'
deny_command 'rm -fr build'
deny_command 'rm -Rfv build'
deny_command 'rm -r build -f'
deny_command 'rm --force --recursive build'
deny_command 'cd /tmp && rm -rf x'
deny_command '/bin/rm -rf build'
deny_command '\rm -rf build'
# shellcheck disable=SC2016 # the guard must see the unexpanded $(...)
deny_command 'echo $(rm -rf build)'
deny_command '(cd /tmp; rm -rf x)'
deny_command 'bash -c "cd /tmp && rm -rf x"'
deny_command 'git push --force'
deny_command 'git push -f origin main'
deny_command 'git push -uf origin feature'
deny_command 'git -C repo push origin --force'
deny_command 'git push --mirror'
deny_command 'git push origin +main'
deny_command 'git commit -m "wip" && git push -f'
deny_command 'git reset --hard origin/main'
deny_command 'git reset --hard'

allow_command 'rm build/output.txt'
allow_command 'rm -r build'
allow_command 'rm -f build/output.txt'
allow_command 'git push -u origin feature'
allow_command 'git push --force-with-lease=feature:abc123 origin feature'
allow_command 'git reset --soft HEAD~1'
allow_command 'git reset HEAD file.txt'
allow_command 'echo "use rm carefully"'
allow_command "git commit -m 'fix push -f bug'"
allow_command $'rm -r build\nls -f'
allow_command $'git push origin main\nls -f'

deny_file '.env'
deny_file '/repo/.env'
deny_file '/repo/apps/api/.env.local'
deny_file '/repo/.git/config'
check deny NotebookEdit notebook_path '/repo/.git/hooks/pre-commit'
check deny Write file_path '/repo/.env.production'

allow_file '/repo/.env.example'
allow_file '/repo/apps/api/.env.template'
allow_file '/repo/.envrc'
allow_file '/repo/.github/workflows/ci.yml'
allow_file '/repo/.gitignore'
allow_file '/repo/src/env.ts'

check allow Read file_path '/repo/.env'

if [[ $failures -gt 0 ]]; then
    echo "$failures failed"
    exit 1
fi
echo "all guard tests passed"
