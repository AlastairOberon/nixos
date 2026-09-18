{ config, pkgs, ... }:

{
  xdg.configFile."yazi/keymap.toml".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/yazi/src/keymap.toml";
  xdg.configFile."yazi/yazi.toml".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/yazi/src/yazi.toml";
  xdg.configFile."yazi/theme.toml".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.cache/wal/theme.toml";
}
