{ config, pkgs, inputs, ... }:

{
  # ==========================================
  # --- BINARY CACHE ---
  # ==========================================
  # This replaces the need for command-line arguments. 
  # It tells Nix to pull the pre-compiled Wine environment.
  nix.settings = {
    extra-substituters = [ "https://cache.forall.systems" ];
    extra-trusted-public-keys = [ "cache.forall.systems:5PmD7QO4MSF8YgyRZtkSGXRDo96H3bybIf2SsQh8ScI=" ];
  };

  # ==========================================
  # --- OVERLAYS ---
  # ==========================================
  # Injects the affinity-nix packages into your pkgs variable
  nixpkgs.overlays = [ 
    inputs.affinity-nix.overlays.default 
  ];

  # ==========================================
  # --- PACKAGES ---
  # ==========================================
  environment.systemPackages = with pkgs; [
    affinity-v3
    
    # You can also add specific launchers if you prefer:
    # affinity-photo
    # affinity-designer
    # affinity-publisher
  ];

  # ==========================================
  # --- ENVIRONMENT VARIABLES (Optional) ---
  # ==========================================
  # If you experience Wayland scaling issues with Wine, 
  # you can force X11 scaling here just for Wine apps.
  # environment.sessionVariables = {
  #   WINEFSYNC = "1"; # Improves performance in Wine
  # };
}
