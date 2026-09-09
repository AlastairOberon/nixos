{ config, pkgs, ... }:

{
    xdg.configFile."hypr/hyprlock".source = 
        config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/configs/nvim/src/hyprlock";
    xdg.configFile."hypr/userconfigs".source = 
        config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/configs/nvim/src/userconfigs";
    xdg.configFile."hypr/hyprland.lua".source = 
        config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/configs/nvim/src/hyprland.lua";
    xdg.configFile."hypr/hyprlock.conf".source = 
        config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/configs/nvim/src/hyprlock.conf";

}
