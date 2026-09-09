{ pkgs, ... }:

{
  virtualisation.oci-containers.containers = {
    searxng = {
      image = "docker.io/searxng/searxng:latest";
      autoStart = true;

      environment = {
        SEARXNG_DEFAULT_CONFIG = "config/searxng.conf";
        SEARXNG_LOG_LEVEL = "INFO";
      };

      ports = [
        "8181:8080"
      ];

      # I updated the relative paths (./config) to absolute paths matching 
      # the directory structure you used for SillyTavern. 
      volumes = [
        "/mnt/data/Docker_Main/SearXNG/config:/etc/searxng:Z"
        "/mnt/data/Docker_Main/SearXNG/data:/var/cache/searxng:Z"
        "/mnt/data/Docker_Main/SearXNG/extensions:/usr/share/searxng/extensions:Z"
      ];

      # Traefik labels translate directly into this attribute block
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.searxng.rule" = "Host(`searx.yourdomain.com`)";
        "traefik.http.routers.searxng.entrypoints" = "websecure";
        "traefik.http.routers.searxng.tls.certresolver" = "letsencrypt";
      };

      extraOptions = [
        # DNS settings are passed as extra podman run arguments
        "--dns=8.8.8.8"
        "--dns=1.1.1.1"
        
        # If Traefik requires this container to be on a specific network to route traffic,
        # uncomment the line below. Note: You must create this network manually via 
        # `podman network create searxng-net` or via a systemd preStart script.
        # "--network=searxng-net"
      ];
    };
  };
}
