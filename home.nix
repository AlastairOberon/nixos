{ config, pkgs, inputs, ... }:

{
  home.username = "alastair_oberon";
  home.homeDirectory = "/home/alastair_oberon";

  imports = [
      ./modules/configs/yazi/yazi_main.nix
      ./modules/configs/zsh/zsh_main.nix
      ./modules/configs/wal/pywal_main.nix
      ./modules/configs/waypaper/waypaper_main.nix
      ./modules/configs/starship/starship_main.nix
      ./modules/configs/quickshell/quickshell_main.nix
      ./modules/configs/nvim/nvim_main.nix
      # ./modules/configs/hypr/hypr_main.nix
  ];

  # You can move user-specific packages out of applications.nix and into here later!
  home.packages = with pkgs; [
    # Packages intended just for you go here
  ];

  programs.home-manager.enable = true;
  # Do not change this value. It defines the state version for compatibility.
  home.stateVersion = "23.11"; 
}
