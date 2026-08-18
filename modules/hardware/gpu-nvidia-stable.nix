{ config, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];
  
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    
    # RTX 2000-series and newer run beautifully on the open drivers!
    open = true; 
    
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
}
