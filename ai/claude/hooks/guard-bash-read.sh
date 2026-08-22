#!/usr/bin/env bash
# PreToolUse guard for Bash commands that would read sensitive files.
# Complements the Read(...) rules in permissions, which do not cover Bash.
# Reads the hook payload from stdin, emits a permission decision on stdout.
# Usage: registered as a PreToolUse hook with matcher "Bash".

set -uo pipefail

# Patterns kept in sync by hand with the permissions.deny / permissions.ask
# entries in personal.json and professional.json.
readonly DENY_PATTERNS=(
    '*.jks'
    '*.key'
    '*.keystore'
    '*.mobileprovision'
    '*.p12'
    '*.pem'
    '*.pfx'
    '.env'
    '.env.*'
    '*/.env'
    '*/.env.*'
    '*/secrets/*'
    'secrets/*'
    '*/.gnupg/*'
    '.netrc'
    '*/.netrc'
    '*/.ssh/*'
)

readonly ASK_PATTERNS=(
    '*credential*'
    '*secret*'
)

decision() {
    # decision <allow|ask|deny> <reason>
    jq -cn \
        --arg decision "$1" \
        --arg reason "$2" \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $decision, permissionDecisionReason: $reason}}'
    exit 0
}

# A guard that fails closed on a missing dependency is worse than no guard:
# it would break every Bash call in the session.
if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

payload="$(cat)"
command_line="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)"

if [[ -z "$command_line" ]]; then
    exit 0
fi

# Strip shell punctuation so redirections and separators do not stay glued to
# the paths, then keep the tokens that look like one.
read -r -a tokens <<<"$(printf '%s' "$command_line" | tr '<>|;&()`"'"'" ' ' | tr -s ' ')"

# Case-insensitive on purpose: CredentialsProvider.swift and SecretStore.swift
# are the common spellings in Swift codebases.
shopt -s nocasematch

matches_any() {
    # matches_any <token> <pattern>...
    local token="$1"
    shift
    local pattern
    for pattern in "$@"; do
        # Glob matching is intentional: patterns are globs, not literals
        # shellcheck disable=SC2053
        [[ "$token" == $pattern ]] && return 0
        # shellcheck disable=SC2053
        [[ "${token##*/}" == $pattern ]] && return 0
    done
    return 1
}

ask_reason=""

for token in "${tokens[@]}"; do
    [[ "$token" != *[/.~]* ]] && continue

    if matches_any "$token" "${DENY_PATTERNS[@]}"; then
        decision deny "Bash command reads a sensitive path ($token), blocked by guard-bash-read."
    fi

    if [[ -z "$ask_reason" ]] && matches_any "$token" "${ASK_PATTERNS[@]}"; then
        ask_reason="Bash command touches $token, which matches a credential/secret name pattern."
    fi
done

if [[ -n "$ask_reason" ]]; then
    decision ask "$ask_reason"
fi

exit 0
