{ pkgs, ... }:

{
  home.packages = [ pkgs.khal ];
  
  # Maps the raw text file directly to ~/.config/khal/config
  xdg.configFile."khal/config".source = ./src/config;
}
