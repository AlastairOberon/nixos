{ config, pkgs, ... }:

{
  xdg.configFile."fastfetch".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/fastfetch/src";
}
