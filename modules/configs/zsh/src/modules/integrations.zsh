# --- Zoxide (Smarter cd) ---
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd)"

# --- FZF Integration ---
command -v fzf &>/dev/null && eval "$(fzf --zsh)"

# --- UV & UVX Completions (Cached to eliminate slow subshells) ---
local comp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
if command -v uv &>/dev/null; then
    if [[ ! -f "$comp_dir/_uv" ]]; then
        mkdir -p "$comp_dir"
        uv generate-shell-completion zsh > "$comp_dir/_uv" 2>/dev/null
    fi
    [[ -f "$comp_dir/_uv" ]] && source "$comp_dir/_uv"
fi
if command -v uvx &>/dev/null; then
    if [[ ! -f "$comp_dir/_uvx" ]]; then
        mkdir -p "$comp_dir"
        uvx --generate-shell-completion zsh > "$comp_dir/_uvx" 2>/dev/null
    fi
    [[ -f "$comp_dir/_uvx" ]] && source "$comp_dir/_uvx"
fi

# --- Atuin (Shell History Sync & Search) ---
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# --- Starship Prompt ---
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
command -v starship &>/dev/null && eval "$(starship init zsh)"

