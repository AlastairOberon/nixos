{ config, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];
  
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; # MX150 requires the closed-source drivers
    nvidiaSettings = true;
    
    # 👇 Changed to the 580 branch to restore MX150 compatibility
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0"; 
    };
  };

  environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
}
