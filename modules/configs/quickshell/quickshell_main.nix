{ config, pkgs, ... }:

{
    # This will create a chained symlink that remains fully editable!
    xdg.configFile."quickshell/shell.qml".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/quickshell/src/shell.qml";
    xdg.configFile."quickshell/bar".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/quickshell/src/bar";
    xdg.configFile."quickshell/theme".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/quickshell/src/theme";
    xdg.configFile."quickshell/assets".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/quickshell/src/assets";
}
