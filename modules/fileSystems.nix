{ config, pkgs, ... }:

{
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/3406d475-c831-4358-b0d7-02edf5367150";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=1s" ];
  };
}
