{ config, pkgs, ... }:

{
  xdg.configFile."hypr/hyprlock".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/hypr/src/hyprlock";
  xdg.configFile."hypr/userconfigs".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/hypr/src/userconfigs";
  xdg.configFile."hypr/hyprland.lua".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/hypr/src/hyprland.lua";
  xdg.configFile."hypr/hyprlock.conf".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/hypr/src/hyprlock.conf";
}
