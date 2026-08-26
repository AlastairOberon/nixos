{ ... }:

let
  # Helper to auto-import all .nix files and valid subdirectories in a directory
  autoImport = dir:
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
      builtins.map (name: dir + "/${name}") toImport;
in
{
  imports = autoImport ./.;
}
