#!/usr/bin/env bash
# Claude Code status line. Claude Code pipes session JSON to stdin and shows
# whatever this prints:
#   <host> <folder> <branch> [✗ dirty] [worktree] [PR #n]
#   <model> [effort]  <context bar> <pct>% <used>/<window>  [$cost] [5h/7d limits]
# Colors follow starship/starship.toml; the host is yellow anywhere but the Mac
# so a remote box stands out. Must stay bash 3.2 compatible (macOS /bin/bash).

input=$(cat)

# One jq call. Fields are joined with \037 because `read` collapses empty
# fields between whitespace separators such as tabs.
IFS=$'\037' read -r cwd model effort pct used window cost pr_num pr_url worktree five_h seven_d << EOF
$(printf '%s' "$input" | jq -r '
  def int: if . == null then "" else floor end;
  [
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.effort.level // ""),
    (.context_window.used_percentage | int),
    (.context_window.total_input_tokens | int),
    (.context_window.context_window_size | int),
    (.cost.total_cost_usd // ""),
    (.pr.number // ""),
    (.pr.url // ""),
    (.workspace.git_worktree // .worktree.name // ""),
    (.rate_limits.five_hour.used_percentage | int),
    (.rate_limits.seven_day.used_percentage | int)
  ] | map(tostring) | join("\u001f")' 2> /dev/null)
EOF

c() { printf '\033[%sm%s\033[0m' "$1" "$2"; }

# 182000 -> 182k, 1000000 -> 1M, 1500000 -> 1.5M
tokens() {
    local n=${1:-0}
    if [ "$n" -ge 1000000 ]; then
        if [ $((n % 1000000)) -eq 0 ]; then
            printf '%dM' $((n / 1000000))
        else
            printf '%d.%dM' $((n / 1000000)) $((n % 1000000 / 100000))
        fi
    elif [ "$n" -ge 1000 ]; then
        printf '%dk' $((n / 1000))
    else
        printf '%d' "$n"
    fi
}

# Line 1: where Claude is running
[ -z "$cwd" ] && cwd=$PWD
host=$(hostname -s 2> /dev/null || hostname)
if [ "$(uname -s)" = Darwin ]; then host_color='1;32'; else host_color='1;33'; fi
if [ "$cwd" = "$HOME" ]; then dir='~'; else dir=${cwd##*/}; fi
line1="$(c "$host_color" "$host") $(c '1;34' "$dir")"

# --no-optional-locks keeps the status line from taking index locks in the repo.
g() { git -C "$cwd" --no-optional-locks "$@" 2> /dev/null; }
if g rev-parse --is-inside-work-tree > /dev/null; then
    branch=$(g symbolic-ref --short -q HEAD || g rev-parse --short HEAD)
    line1="$line1 $(c '1;35' "$branch")"
    [ -n "$(g status --porcelain | head -n 1)" ] && line1="$line1 $(c '1;31' '✗')"
fi
[ -n "$worktree" ] && line1="$line1 $(c 2 "⎇ $worktree")"
if [ -n "$pr_num" ]; then
    # OSC 8 hyperlink: Cmd/Ctrl+click opens the PR in terminals that support it.
    line1="$line1 $(printf '\033]8;;%s\a%s\033]8;;\a' "$pr_url" "$(c 36 "PR #$pr_num")")"
fi

# Line 2: model and how full the context window is
line2=$(c 36 "${model:-Claude}")
[ -n "$effort" ] && line2="$line2 $(c 2 "$effort")"
if [ -n "$pct" ]; then
    if [ "$pct" -ge 90 ]; then bar_color=31; elif [ "$pct" -ge 70 ]; then bar_color=33; else bar_color=32; fi
    filled=$((pct / 10))
    [ "$filled" -gt 10 ] && filled=10
    bar=""
    i=0
    while [ "$i" -lt 10 ]; do
        if [ "$i" -lt "$filled" ]; then bar="$bar█"; else bar="$bar░"; fi
        i=$((i + 1))
    done
    line2="$line2  $(c "$bar_color" "$bar") ${pct}%"
    [ -n "$window" ] && line2="$line2 $(c 2 "$(tokens "$used")/$(tokens "$window")")"
fi
[ -n "$cost" ] && line2="$line2  $(c 33 "$(printf '$%.2f' "$cost")")"
limits=""
[ -n "$five_h" ] && limits="5h ${five_h}%"
[ -n "$seven_d" ] && limits="${limits:+$limits }7d ${seven_d}%"
[ -n "$limits" ] && line2="$line2  $(c 2 "$limits")"

printf '%s\n%s\n' "$line1" "$line2"
