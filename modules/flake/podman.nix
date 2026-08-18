{ pkgs, ... }:

{
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;

  virtualisation.podman = {
    enable = true;
    
    # Create a 'docker' alias for podman so commands like `docker run` seamlessly work
    dockerCompat = true;
    
    # Required for containers under podman-compose to be able to talk to each other
    defaultNetwork.settings.dns_enabled = true;
  };

  # Enable the NVIDIA Container Toolkit for GPU passthrough
  hardware.nvidia-container-toolkit.enable = true;

  environment.systemPackages = with pkgs; [
    podman-compose # The Podman equivalent of docker-compose
    podman-tui     # A great terminal UI for managing containers
    dive           # A tool to explore container image layers
  ];
}
