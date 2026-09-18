# Enable Vi Mode
bindkey -v

# Reduce delay when switching modes (from default 400ms to 15ms)
export KEYTIMEOUT=15

# Cursor shape switching: Beam in insert mode, Block in normal mode
function zle-keymap-select() {
    if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
        echo -ne '\e[2 q' # block
    elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ $1 = 'beam' ]]; then
        echo -ne '\e[6 q' # beam
    fi
}
zle -N zle-keymap-select

_set_cursor_beam() { echo -ne '\e[6 q'; }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _set_cursor_beam

# Standard editing keybindings in Insert Mode
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^W' backward-kill-word

# Home, End, Delete keys
bindkey -M viins '^[[H' beginning-of-line
bindkey -M viins '^[[F' end-of-line
bindkey -M viins '^[[3~' delete-char
bindkey -M vicmd '^[[H' beginning-of-line
bindkey -M vicmd '^[[F' end-of-line
bindkey -M vicmd '^[[3~' delete-char

# Edit current command line in $EDITOR with 'v' in normal mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

