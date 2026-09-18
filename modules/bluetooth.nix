{ config, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Powers on bluetooth at startup
    settings = {
      General = {
        # Automatically syncs Bluetooth device name with your system/host name
        Name = config.networking.hostName;
        Experimental = true; # Recommended for features like battery level reporting
      };
    };
  };
}
