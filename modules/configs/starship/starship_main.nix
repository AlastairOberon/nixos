{ config, pkgs, ... }:

{
    # Tell Starship to read its config directly from the Pywal cache
    xdg.configFile."starship/starship.toml".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.cache/wal/starship.toml";
}
