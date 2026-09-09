{ config, lib, pkgs, ... }:

{
  # Pass options directly to the Realtek kernel module
  boot.extraModprobeConfig = ''
    # Disable Active State Power Management (ASPM) for the rtw89 driver (RTL8852AE)
    # This forces the card to stay awake, fixing micro-stutters and high ping.
    options rtw89_core disable_aspm_l1=1 disable_aspm_l1ss=1
  '';

  services.power-profiles-daemon.enable = true;

  # --- NEW: Lenovo Legion Kernel Module ---
  # This provides the actual driver backend for the lenovo-legion GUI app
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];
  boot.kernelModules = [ "legion-laptop" ];
}
