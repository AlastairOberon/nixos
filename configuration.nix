{ ... }:

{
  # =========================================================================
  # System / Device Name
  # Changing this single value updates your:
  #   1. System hostname (CLI prompt, system identification)
  #   2. Local network name & mDNS (e.g. memosyne.local)
  #   3. Bluetooth broadcast name (visible to phones/headphones)
  # =========================================================================
  networking.hostName = "memosyne";

  imports = [
    ./hardware-configuration.nix
    (if builtins.pathExists ./local-hardware.nix then ./local-hardware.nix else {})
    ./modules
  ];

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;

  # Automated weekly garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Automatically back up existing files that would be clobbered by Home Manager
  home-manager.backupFileExtension = "backup";

  system.stateVersion = "26.05";
}
