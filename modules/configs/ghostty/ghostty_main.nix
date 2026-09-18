{ config, pkgs, ... }:

{
  xdg.configFile."ghostty/config".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/ghostty/src/config";

  # Links dynamic pywal theme generated in ~/.cache/wal/colors-ghostty
  xdg.configFile."ghostty/themes/pywal".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.cache/wal/colors-ghostty";
}
