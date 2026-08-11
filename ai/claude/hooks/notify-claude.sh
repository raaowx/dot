#!/usr/bin/env bash
# Audible notification for Claude Code hooks.
# Usage: notify-claude.sh <ask|done>

event="${1:-done}"
title="Claude"

case "$event" in
    ask)
        message="Tengo una pregunta para ti"
        sound="Hero"
        ;;
    done)
        message="He terminado de hacer cosas"
        sound="Sosumi"
        ;;
    *)
        message="$event"
        sound="Hero"
        ;;
esac

printf '\a'

if [[ "$(uname -s)" == "Darwin" ]]; then
    osascript -e "display notification \"${message}\" with title \"${title}\" sound name \"${sound}\"" >/dev/null 2>&1
elif command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$message" >/dev/null 2>&1
fi

exit 0
