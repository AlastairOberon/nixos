# Aliases
alias ls='ls -color'
alias snapup='sudo snapper -c root create --description "Snapshot_Root $(date +%F_%T)" && sudo snapper -c home create --description "Snapshot_Home $(date +%F_%T)"'
alias snaplist='echo "Root snapshots:" && sudo snapper -c root list && echo "" && echo "Home snapshots:" && sudo snapper -c home list'
alias cd="z"
