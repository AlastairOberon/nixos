# --- Interactive TLDR / Help Widget ---
run-tldr() {
    # Only run if the buffer isn't empty
    if [[ -n ${BUFFER// /} ]]; then
        echo "" # Move to a new line so we don't overwrite the prompt
        local -a words
        words=(${(z)BUFFER})
        local cmd=${words[1]}
        # If prefixed by sudo/doas/env, use the target command
        if [[ "$cmd" == (sudo|doas|env) && -n "${words[2]}" ]]; then
            cmd=${words[2]}
        fi

        if command -v tldr &>/dev/null; then
            tldr "$cmd"
        elif command -v tealdeer &>/dev/null; then
            tealdeer "$cmd"
        elif command -v man &>/dev/null; then
            man "$cmd"
        else
            echo "Neither tldr nor tealdeer is installed. (Install via nix: pkgs.tealdeer)"
        fi
        zle redisplay
    fi
}

# Register the function as a Zle widget
zle -N run-tldr

# Bind to Alt+h in both Vi insert and normal modes
bindkey -M viins '\eh' run-tldr
bindkey -M vicmd '\eh' run-tldr

