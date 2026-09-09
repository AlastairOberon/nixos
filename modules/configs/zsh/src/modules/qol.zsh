# Automatically escape URLs and special characters when pasting
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# Magic Enter
function magic-enter() {
    if [[ -z $BUFFER ]]; then
        echo ""
        ls --color=auto
        if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
            echo ""
            git status -s
        fi
        zle redisplay
    else
        zle accept-line
    fi
}
zle -N magic-enter
bindkey '^M' magic-enter # Binds the Enter key
