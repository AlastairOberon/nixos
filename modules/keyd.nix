{ config, pkgs, ... }:

{
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            grave = "overload(meta, grave)";
          };
        };
      };
    };
  };
}
