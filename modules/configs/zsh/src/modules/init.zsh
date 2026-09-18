ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not installed
if [[ ! -d "$ZINIT_HOME" ]]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source / Load Zinit
source "${ZINIT_HOME}/zinit.zsh"

