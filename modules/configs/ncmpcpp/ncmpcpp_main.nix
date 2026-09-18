{ config, pkgs, ... }:

{
  xdg.configFile."ncmpcpp/config".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/ncmpcpp/src/config";
}
