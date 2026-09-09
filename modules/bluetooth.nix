{ config, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Powers on bluetooth at startup
    settings = {
      General = {
        Experimental = true; # Recommended for features like battery level reporting
      };
    };
  };
}
