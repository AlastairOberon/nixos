{ config, pkgs, ... }:

{
  xdg.configFile."rofi/config.rasi".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/rofi/src/config.rasi";
}
