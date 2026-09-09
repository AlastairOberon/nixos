{ config, pkgs, ... }:

{
    xdg.configFile."nvim/after".source = 
        config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/configs/nvim/src/after";
    xdg.configFile."nvim/lua".source = 
        config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/configs/nvim/src/lua";
    xdg.configFile."nvim/init.lua".source = 
        config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/configs/nvim/src/init.lua";
    xdg.configFile."nvim/lazy-lock.json".source = 
        config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/configs/nvim/src/lazy-lock.json";

}
