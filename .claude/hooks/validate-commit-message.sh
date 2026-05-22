#!/usr/bin/env bash
#
# validate-commit-message.sh
#
# Pre-commit message validator for Claude Code.
# Enforces the commit message convention documented in CLAUDE.md.
#
# Compatible with bash 3.2+ (macOS system bash).
#
# Exit codes:
#   0  → commit allowed (or not a git commit; nothing to validate)
#   1  → operational error (jq missing, malformed input, etc.) — shown to user
#   2  → commit rejected (didactic message shown to Claude for retry)

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

ALLOWED_AREA_TAGS=(
  "[SHELL]" "[ZED]" "[XCODE]" "[NANO]"
  "[TERMINAL]" "[GIT]" "[RECTANGLE]" "[CLAUDE]"
)

ALLOWED_ROOT_TAGS=(
  "[README]" "[LICENSE]" "[GITIGNORE]" "[PROJECT]" "[CONFIG]"
)

FORBIDDEN_TAGS=(
  "[ADD]" "[FIX]" "[REFACTOR]" "[FEATURE]" "[FEAT]"
  "[UPDATE]" "[UPD]" "[UPGRADE]" "[UPG]"
  "[RENAME]" "[REN]" "[DELETE]" "[DEL]"
  "[REMOVE]" "[REM]"
)

# Suggestion text for forbidden tags. Returns the suggestion via stdout.
# Add new entries by appending a case branch.
forbidden_suggestion() {
  case "$1" in
    "[ADD]")      echo "use the area tag (e.g. [SHELL], [ZED]) with 'Add' as the verb in the description." ;;
    "[FIX]")      echo "use the area tag with 'Fix' as the verb in the description." ;;
    "[REFACTOR]") echo "use the area tag with 'Refactor' as the verb. Refactors that touch multiple areas must be split into separate commits." ;;
    "[FEATURE]")  echo "use the area tag with the appropriate verb (Add, Update, etc.)." ;;
    "[FEAT]")     echo "use the area tag with the appropriate verb (Add, Update, etc.)." ;;
    "[UPDATE]")   echo "use the area tag with 'Update' as the verb, or [PROJECT] for multi-file root changes." ;;
    "[UPD]")      echo "use the area tag with 'Update' as the verb, or [PROJECT] for multi-file root changes." ;;
    "[UPGRADE]")  echo "use the area tag with 'Upgrade' as the verb." ;;
    "[UPG]")      echo "use the area tag with 'Upgrade' as the verb." ;;
    "[RENAME]")   echo "use the area tag with 'Rename' as the verb." ;;
    "[REN]")      echo "use the area tag with 'Rename' as the verb." ;;
    "[DELETE]")   echo "use the area tag with 'Delete' as the verb." ;;
    "[DEL]")      echo "use the area tag with 'Delete' as the verb." ;;
    "[REMOVE]")   echo "use the area tag with 'Delete' as the verb (we use 'Delete' over 'Remove' by convention)." ;;
    "[REM]")      echo "use the area tag with 'Delete' as the verb (we use 'Delete' over 'Remove' by convention)." ;;
    *)            echo "no suggestion available." ;;
  esac
}

# ─── Operational checks ──────────────────────────────────────────────────────

# Check: jq is installed.
if ! command -v jq >/dev/null 2>&1; then
  echo "Hook error: 'jq' is required but not installed." >&2
  echo "Install with: brew install jq" >&2
  exit 1
fi

# Read stdin (JSON payload from Claude Code).
INPUT="$(cat)"

# Check: input is valid JSON.
if ! echo "$INPUT" | jq empty >/dev/null 2>&1; then
  echo "Hook error: received invalid JSON on stdin." >&2
  echo "This may indicate a Claude Code version mismatch." >&2
  exit 1
fi

# Extract the bash command being executed.
COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"

# If the command is empty, nothing to validate. Pass through.
if [ -z "$COMMAND" ]; then
  exit 0
fi

# ─── Git commit detection ────────────────────────────────────────────────────

# Only validate if the command is a git commit.
# We check that "git commit" appears as actual command invocation, not embedded in text.
#
# Strategy: split the command into segments at shell separators (;, &&, ||, |),
# then check if any segment starts with optional whitespace followed by "git commit".

is_git_commit() {
  local cmd="$1"
  # Normalize: replace shell separators with newlines so we can iterate segments.
  local normalized
  normalized="$(echo "$cmd" | sed -E 's/(&&|\|\||;|\|)/\
/g')"

  local segment
  while IFS= read -r segment; do
    # Trim leading whitespace
    segment="$(echo "$segment" | sed -E 's/^[[:space:]]+//')"
    # Check if this segment begins with `git commit` followed by whitespace or end.
    if [[ "$segment" =~ ^git[[:space:]]+commit([[:space:]]|$) ]]; then
      return 0
    fi
  done <<< "$normalized"

  return 1
}

if ! is_git_commit "$COMMAND"; then
  exit 0
fi

# ─── Message extraction ──────────────────────────────────────────────────────

MESSAGE=""

# Try -m "message" or --message="message" or --message "message".
# Handles both single and double quotes.
extract_m_flag() {
  local cmd="$1"
  local extracted
  extracted="$(echo "$cmd" | grep -oE "(-m|--message)[= ]+(\"[^\"]*\"|'[^']*')" | head -n1 | sed -E "s/^(-m|--message)[= ]+//; s/^[\"']//; s/[\"']\$//")"
  echo "$extracted"
}

# Try -F <file> or --file <file>
extract_f_flag() {
  local cmd="$1"
  local file
  file="$(echo "$cmd" | grep -oE "(-F|--file)[= ]+[^ ]+" | head -n1 | sed -E 's/^(-F|--file)[= ]+//')"
  if [ -n "$file" ] && [ -f "$file" ]; then
    cat "$file"
  fi
}

MESSAGE="$(extract_m_flag "$COMMAND")"

if [ -z "$MESSAGE" ]; then
  MESSAGE="$(extract_f_flag "$COMMAND")"
fi

# If still empty, the commit uses the editor — we can't validate.
if [ -z "$MESSAGE" ]; then
  cat >&2 <<'EOF'
✗ Commit rejected: cannot validate commit message.

This hook can only validate commit messages passed via -m / --message or -F / --file.
Editor-based commits (`git commit` without -m or -F) cannot be inspected before execution.

Please use:
  git commit -m "[TAG] Description"

See CLAUDE.md > "Commit message convention" for details.
EOF
  exit 2
fi

# Take only the first line (subject) for validation; ignore body.
SUBJECT="$(echo "$MESSAGE" | head -n1)"

# ─── Helper functions ────────────────────────────────────────────────────────

array_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

print_allowed_tags() {
  echo "Allowed area tags:" >&2
  echo "  ${ALLOWED_AREA_TAGS[*]}" >&2
  echo "Allowed root-level tags:" >&2
  echo "  ${ALLOWED_ROOT_TAGS[*]}" >&2
}

reject() {
  local issue="$1"
  cat >&2 <<EOF
✗ Commit message rejected by validation hook.

Your message: $SUBJECT
Issue:        $issue

EOF
  print_allowed_tags
  echo "" >&2
  echo "See CLAUDE.md > \"Commit message convention\" for details." >&2
  exit 2
}

# ─── Validations ─────────────────────────────────────────────────────────────

# Validation 1: must start with [TAG] (uppercase letters only, in brackets).
if ! [[ "$SUBJECT" =~ ^\[[A-Z]+\] ]]; then
  reject "Message must start with an area or root-level tag in the format [TAG]."
fi

# Extract the first tag (with brackets).
FIRST_TAG="$(echo "$SUBJECT" | grep -oE '^\[[A-Z]+\]')"

# Validation 2: tag must not be in the forbidden list.
if array_contains "$FIRST_TAG" "${FORBIDDEN_TAGS[@]}"; then
  SUGGESTION="$(forbidden_suggestion "$FIRST_TAG")"
  reject "Tag $FIRST_TAG is forbidden. Instead, $SUGGESTION"
fi

# Validation 3: tag must be in the allowed list (area or root).
if ! array_contains "$FIRST_TAG" "${ALLOWED_AREA_TAGS[@]}" \
   && ! array_contains "$FIRST_TAG" "${ALLOWED_ROOT_TAGS[@]}"; then
  reject "Tag $FIRST_TAG is not recognized. If a new area was added to the repository, both CLAUDE.md and this hook must be updated to include the new tag."
fi

# Validation 4: only one tag allowed.
# Strict mode: any second [XXX] in the message is a violation.
SECOND_TAG="$(echo "$SUBJECT" | sed -E "s/^\[[A-Z]+\]//" | grep -oE '\[[A-Z]+\]' | head -n1 || true)"
if [ -n "$SECOND_TAG" ]; then
  reject "Multiple tags detected ($FIRST_TAG and $SECOND_TAG). If both changes belong to the same area, chain them with '&' (e.g. 'Add X & update Y'). If they belong to different areas, split into separate commits."
fi

# Validation 5: description format.
# After the tag, either:
#   - nothing (e.g. "[LICENSE]")
#   - exactly one space, then a capital letter starting the description (e.g. "[SHELL] Add ...")
# Note: using sed instead of ${SUBJECT#$FIRST_TAG} because bash treats brackets
# in parameter expansion as glob patterns, not literals.
REMAINDER="$(echo "$SUBJECT" | sed -E 's/^\[[A-Z]+\]//')"
if [ -n "$REMAINDER" ]; then
  if ! [[ "$REMAINDER" =~ ^\ [A-Z] ]]; then
    reject "After the tag, the description must start with a single space and a capital letter (e.g. '$FIRST_TAG Add something')."
  fi
fi

# ─── All validations passed ─────────────────────────────────────────────────

exit 0
