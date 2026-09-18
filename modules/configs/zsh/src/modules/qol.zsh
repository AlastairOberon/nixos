# --- Fast Bracketed URL Pasting ---
# bracketed-paste-magic prevents paste lag caused by url-quote-magic
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# --- Magic Enter ---
# Pressing Enter on an empty prompt prints directory contents & git status
function magic-enter() {
    if [[ -z ${BUFFER// /} ]]; then
        echo ""
        ls --color=auto
        if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
            echo ""
            git status -sb
        fi
        zle redisplay
    else
        zle accept-line
    fi
}
zle -N magic-enter

# Bind Enter in both Vi insert and normal modes
bindkey -M viins '^M' magic-enter
bindkey -M vicmd '^M' magic-enter
bindkey '^M' magic-enter

