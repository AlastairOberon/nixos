{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules
  ];

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
