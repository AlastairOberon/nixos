{ ... }:

{
  imports = [
    ./boot.nix
    ./network.nix
    ./bluetooth.nix
    ./locale.nix
    ./users.nix
    ./graphics.nix
    ./applications.nix
    ./fonts.nix
    ./portals.nix
    ./keyd.nix
    ./fileSystems.nix
    ./hardware/gpu-nvidia-stable.nix
    ./hardwareConfig.nix
  ];
}
