{ pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users."alastair_oberon" = {
    isNormalUser = true;
    description = "Alastair Oberon";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
