{ ... }:

{
  imports = [
    ./boot.nix
    ./network.nix
    ./locale.nix
    ./users.nix
    ./graphics.nix
    ./applications.nix
    ./fonts.nix
    ./portals.nix
    ./keyd.nix
    ./hardware/gpu-nvidia-legacy.nix
  ];
}
