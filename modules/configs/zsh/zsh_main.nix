{ config, pkgs, ... }:

{
    home.file.".zshrc".source = ./src/.zshrc;
    xdg.configFile."zsh/modules".source = ./src/modules;
}
