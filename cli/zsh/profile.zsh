# === === === ZSH PROFILE === === === #
[ -z "$PS1" ] && return # Skip profile sourcing for not interactive shells
SHELL_PROFILE="$HOME/.shell_profile"
if [ -f "$SHELL_PROFILE" ]; then
  . "$SHELL_PROFILE"
fi
