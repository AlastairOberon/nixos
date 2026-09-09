{ pkgs, ... }:

{
  virtualisation.oci-containers.containers = {
    sillytavern = {
      image = "ghcr.io/sillytavern/sillytavern:latest";
      autoStart = true;

      environment = {
        NODE_ENV = "production";
        FORCE_COLOR = "1";
      };

      ports = [
        "8787:8000"
      ];

      volumes = [
        "/mnt/data/Docker_Main/SillyTavern/config:/home/node/app/config:Z"
        "/mnt/data/Docker_Main/SillyTavern/data:/home/node/app/data:Z"
        "/mnt/data/Docker_Main/SillyTavern/plugins:/home/node/app/plugins:Z"
        "/mnt/data/Docker_Main/SillyTavern/extensions:/home/node/app/public/scripts/extensions/third-party:Z"
      ];

      extraOptions = [
        "--hostname=sillytavern"
        "--dns=1.1.1.1"
        "--dns=1.0.0.1"
      ];
    };
  };
}
