{ config, pkgs, inputs, ... }:

{
    # 1. Install the bleeding-edge Yazi package via Home Manager
    home.packages = [
        inputs.yazi.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # 2. Tell Home Manager to symlink your raw config files!
    # This replaces the need for Stow entirely.
    # xdg.configFile."yazi/yazi.toml".source = ./src/yazi.toml;
    xdg.configFile."yazi/keymap.toml".source = ./src/keymap.toml;
    xdg.configFile."yazi/yazi.toml".source = ./src/yazi.toml;
    xdg.configFile."yazi/theme.toml".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.cache/wal/theme.toml";
}
