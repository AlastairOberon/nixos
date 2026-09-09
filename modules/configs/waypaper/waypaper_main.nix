{ config, pkgs, ... }:

{
    # This creates a symlink pointing directly to your live Git repository.
    # Waypaper can write to it, and your changes are saved instantly!
    xdg.configFile."waypaper/config.ini".source = 
        config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/configs/waypaper/src/config.ini";
}
