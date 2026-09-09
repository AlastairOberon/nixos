#Plugins (Loaded asynchronously in the background)
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light marlonrichert/zsh-autocomplete

#Autocomplete
zstyle ':autocomplete:*' list-lines 20
bindkey '\r' '.self-insert'
zstyle ':autocomplete:*' min-delay 0.1
#zstyle ':autocomplete:*' min-input 3
zstyle ':fzf-tab:complete:paru:*' fzf-preview '[[ -n $word ]] && paru -Si $word 2>/dev/null'
zstyle ':fzf-tab:complete:pacman:*' fzf-preview '[[ -n $word ]] && pacman -Si $word 2>/dev/null'
#zstyle ':fzf-tab:complete:pacman:*' fzf-preview 'pacman -Si $word'
#zstyle ':fzf-tab:complete:paru:*' fzf-preview 'paru -Si $word'
zstyle ':fzf-tab:complete:uv:*' fzf-preview 'uv pip show $word 2>/dev/null'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-variable-):*' fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers'

#History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm: {a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
