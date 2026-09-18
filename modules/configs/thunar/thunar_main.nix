{ config, pkgs, ... }:

{
  xdg.configFile."Thunar/uca.xml".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/thunar/src/uca.xml";
}
