{ pkgs, ... }:

{
  # ---------------------------------------------------------
  # Container Engine: Standard Docker
  # ---------------------------------------------------------
  virtualisation.docker = {
    enable = true;
    
    # Automatically prune unused images and containers weekly
    autoPrune.enable = true;
    autoPrune.dates = "weekly";
  };

  # Enable the NVIDIA Container Toolkit for GPU passthrough
  hardware.nvidia-container-toolkit.enable = true;

  environment.systemPackages = with pkgs; [
    docker-compose # Official compose for compatibility
    lazydocker     # Terminal UI for managing Docker containers
    dive           # Tool to explore container image layers
  ];
}
