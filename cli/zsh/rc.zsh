# === === === ZSH RC === === === #
[ -z "$PS1" ] && return # Skip profile sourcing for not interative shells
SHELL_PROFILE="$HOME/.shell_profile"
if [ -f "$SHELL_PROFILE" ]; then
  . "$SHELL_PROFILE"
fi
