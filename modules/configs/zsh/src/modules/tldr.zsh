# --- Tealdeer Interactive Help ---
run-tldr() {
    # Only run if the buffer isn't empty
    if [[ -n $BUFFER ]]; then
        echo "" # Move to a new line so we don't overwrite the prompt
        # Get the first word of the command line
        local cmd=${BUFFER%% *}
        tldr "$cmd"
        zle redisplay
    fi
}

# Register the function as a Zle (Zsh Line Editor) widget
zle -N run-tldr

# Bind it to Alt+h (Escape + h in some terminals)
bindkey '\eh' run-tldr
