{ ... }:

let
  # Helper to auto-import a directory if it exists
  importDirIfExists = dir:
    if builtins.pathExists dir then
      let
        files = builtins.readDir dir;
        toImport = builtins.filter (name:
          let
            type = files.${name};
          in
            (type == "regular" && name != "default.nix" && builtins.match "[^_].*\\.nix" name != null) ||
            (type == "directory" && builtins.pathExists (dir + "/${name}/default.nix") && builtins.match "[^_].*" name != null)
        ) (builtins.attrNames files);
      in
        builtins.map (name: dir + "/${name}") toImport
    else
      [];
in
{
  imports = [
    ./hardware-configuration.nix
    ./modules
  ] ++ (importDirIfExists ./flake_apps);

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
