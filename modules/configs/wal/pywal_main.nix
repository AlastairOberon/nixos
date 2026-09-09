{ config, pkgs, ... }:

{
    # 1. Link your templates and colorschemes directly into ~/.config/wal/
    xdg.configFile."wal/templates".source = ./src/templates;
    # xdg.configFile."wal/colorschemes".source = ./src/colorschemes;
}
