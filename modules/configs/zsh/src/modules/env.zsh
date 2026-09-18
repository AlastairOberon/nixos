# Ensure unique entries in PATH and LD_LIBRARY_PATH
typeset -U PATH path LD_LIBRARY_PATH ld_library_path

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# User binaries
path=("$HOME/.local/bin" $path)

# Go configuration (avoids slow subshell call to `go env GOPATH`)
export GOPATH="${GOPATH:-$HOME/go}"
path=($path "$GOPATH/bin")

# Default Applications
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="zen-browser"

# Source external environment variables if present
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

