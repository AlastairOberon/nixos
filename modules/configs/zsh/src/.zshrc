# Define the modules directory with fallback to repository src if not yet linked
ZSH_MODS="${ZSH_MODS:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh/modules}"
if [[ ! -d "$ZSH_MODS" && -d "/etc/nixos/modules/configs/zsh/src/modules" ]]; then
    ZSH_MODS="/etc/nixos/modules/configs/zsh/src/modules"
fi

# Source modules in logical dependency order
source "$ZSH_MODS/env.zsh"
source "$ZSH_MODS/init.zsh"
source "$ZSH_MODS/plugins.zsh"
source "$ZSH_MODS/keybinds.zsh"
source "$ZSH_MODS/aliases.zsh"
source "$ZSH_MODS/integrations.zsh"
source "$ZSH_MODS/yazi.zsh"
source "$ZSH_MODS/tldr.zsh"
source "$ZSH_MODS/qol.zsh"
source "$ZSH_MODS/intro.zsh"

