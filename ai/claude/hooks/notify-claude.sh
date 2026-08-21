#!/usr/bin/env bash
# Audible notification for Claude Code hooks.
# Reads the hook payload from stdin to title the notification per session, so
# concurrent sessions on different worktrees stay distinguishable.
# Usage: notify-claude.sh <ask|done|any other text>

set -uo pipefail

# First thing, before any dependency can slow it down or fail.
printf '\a'

event="${1:-done}"
title="Claude"

# --- Session identity -------------------------------------------------------

# Losing the title detail is preferable to losing the notification, so every
# step below degrades instead of failing.
cwd=""
if command -v jq >/dev/null 2>&1; then
    cwd="$(cat | jq -r '.cwd // empty' 2>/dev/null)"
fi

if [[ -n "$cwd" ]]; then
    # --git-common-dir instead of --show-toplevel: inside a worktree the former
    # still points at the main repository, which is the name worth showing.
    common_dir="$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null)"

    if [[ -n "$common_dir" ]]; then
        [[ "$common_dir" != /* ]] && common_dir="$cwd/$common_dir"
        repo="$(basename "$(dirname "$(cd "$common_dir" 2>/dev/null && pwd)")")"
        branch="$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)"

        if [[ -n "$repo" && -n "$branch" ]]; then
            title="Claude: $repo/$branch"
        elif [[ -n "$repo" ]]; then
            title="Claude: $repo"
        fi
    fi
fi

# --- Localisation -----------------------------------------------------------

locale="${LC_ALL:-${LANG:-}}"
if [[ -z "$locale" && "$(uname -s)" == "Darwin" ]]; then
    # A hook does not necessarily inherit LANG on macOS; fall back to the
    # system-wide preference.
    locale="$(defaults read -g AppleLocale 2>/dev/null)"
fi

case "$event" in
    ask)
        if [[ "$locale" == es* ]]; then
            body="Tengo una pregunta para ti"
        else
            body="I have a question for you"
        fi
        sound="Hero"
        ;;
    done)
        if [[ "$locale" == es* ]]; then
            body="He terminado mi tarea"
        else
            body="I've finished my task"
        fi
        sound="Sosumi"
        ;;
    *)
        body="$event"
        sound="Hero"
        ;;
esac

message="$body"

# --- Delivery ---------------------------------------------------------------

if [[ "$(uname -s)" == "Darwin" ]]; then
    # The AppleScript is built by string concatenation, so a double quote in a
    # branch name would break it.
    escaped_title="${title//\"/\\\"}"
    escaped_message="${message//\"/\\\"}"
    osascript -e "display notification \"${escaped_message}\" with title \"${escaped_title}\" sound name \"${sound}\"" >/dev/null 2>&1
elif command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$message" >/dev/null 2>&1
fi

exit 0
