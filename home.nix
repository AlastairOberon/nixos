{ config, pkgs, inputs, ... }:

let
  # Path to the configs directory
  configsDir = ./modules/configs;

  # Helper to find all entry points in subdirectories of configsDir
  configImports =
    if builtins.pathExists configsDir then
      let
        dirContents = builtins.readDir configsDir;
        subDirs = builtins.filter (name: 
          dirContents.${name} == "directory" && 
          builtins.match "[^_].*" name != null
        ) (builtins.attrNames dirContents);
        getEntryPoint = dirName:
          let
            subDirPath = configsDir + "/${dirName}";
            subDirContents = builtins.readDir subDirPath;
            nixFiles = builtins.filter (fileName:
              (builtins.match ".*_main\\.nix" fileName != null || fileName == "default.nix") &&
              builtins.match "[^_].*" fileName != null
            ) (builtins.attrNames subDirContents);
          in
            if nixFiles == [] then
              []
            else
              [ (subDirPath + "/${builtins.head nixFiles}") ];
      in
        builtins.concatLists (builtins.map getEntryPoint subDirs)
    else
      [];

  # Helper to auto-import a directory if it exists (e.g., for user-specific flake apps)
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
  home.username = "alastair_oberon";
  home.homeDirectory = "/home/alastair_oberon";

  # Automatically back up existing files that would be clobbered by Home Manager
  home.backupFileExtension = "backup";

  imports = configImports ++ (importDirIfExists ./flake_apps);

  # You can move user-specific packages out of applications.nix and into here later!
  home.packages = with pkgs; [
    # Packages intended just for you go here
  ];

  programs.home-manager.enable = true;
  # Do not change this value. It defines the state version for compatibility.
  home.stateVersion = "23.11"; 
}
