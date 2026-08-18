{ pkgs, ... }:

{
  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  environment.systemPackages = [ pkgs.nvtopPackages.amd ];
}
