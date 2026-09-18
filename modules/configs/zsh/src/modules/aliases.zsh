# --- Directory & File Listing ---
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -la --color=auto'
alias l='ls -CF --color=auto'

# --- Snapper Snapshots ---
alias snapup='sudo snapper -c root create --description "Snapshot_Root $(date +%F_%T)" && sudo snapper -c home create --description "Snapshot_Home $(date +%F_%T)"'
alias snaplist='echo "Root snapshots:" && sudo snapper -c root list && echo "" && echo "Home snapshots:" && sudo snapper -c home list'

# --- NixOS Helpers ---
alias nrs='sudo nixos-hardware-sync && sudo nixos-rebuild switch --flake /etc/nixos'
alias nrt='sudo nixos-hardware-sync && sudo nixos-rebuild test --flake /etc/nixos'
alias nsync='sudo nixos-hardware-sync'

# --- Utilities ---
alias g='git'
alias grep='grep --color=auto'
alias ip='ip --color=auto'

