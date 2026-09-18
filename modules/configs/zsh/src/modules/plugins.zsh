# --- Plugins ---
# Additional completion definitions
zinit light zsh-users/zsh-completions

# Initialize completion system with fast 24h dump caching
autoload -Uz compinit
setopt extendedglob
local zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
[[ -d "${zcompdump:h}" ]] || mkdir -p "${zcompdump:h}"
if [[ -n ${zcompdump}(#qN.mh+24) ]]; then
    compinit -d "$zcompdump"
    { zcompile "$zcompdump" } &!
else
    compinit -C -d "$zcompdump"
fi

# Fzf-Tab (Must be loaded after compinit)
zinit light Aloxaf/fzf-tab

# Autosuggestions (Fish-like ghost text)
zinit light zsh-users/zsh-autosuggestions

# Syntax Highlighting (Must be loaded last among plugins)
zinit light zsh-users/zsh-syntax-highlighting

# --- Completion Styling ---
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# --- Fzf-Tab Previews ---
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always -F "$realpath"'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-variable-):*' fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:uv:*' fzf-preview 'uv pip show $word 2>/dev/null'
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word 2>/dev/null'
zstyle ':fzf-tab:complete:git-(checkout|switch):*' fzf-preview 'git log -n 1 --color=always $word 2>/dev/null'

# --- History Configuration ---
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt SHARE_HISTORY

