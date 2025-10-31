# === === === BASH PROFILE === === === #
[ -z "$PS1" ] && return # Skip profile sourcing for not interactive shells
SHELL_PROFILE="$HOME/.shell_profile"
if [ -f "$SHELL_PROFILE" ]; then
  # shellcheck source=../shell/profile.shell
  . "$SHELL_PROFILE"
fi
