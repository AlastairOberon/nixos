{ pkgs, inputs, ... }:

{
  programs.zsh.enable = true;

  users.users."alastair_oberon" = {
    isNormalUser = true;
    description = "Alastair Oberon";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
}
