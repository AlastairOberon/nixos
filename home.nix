{ config, pkgs, lib, inputs, ... }:

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

in
{
  imports = configImports;

  options.dotfiles.path = lib.mkOption {
    type = lib.types.str;
    default = "/etc/nixos";
    description = "Base path to the NixOS configuration repository for out-of-store symlinks";
  };

  config = {
    home.username = "alastair_oberon";
    home.homeDirectory = "/home/alastair_oberon";

    # You can move user-specific packages out of applications.nix and into here later!
    home.packages = with pkgs; [
      # Packages intended just for you go here
    ];

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      music = "${config.home.homeDirectory}/Music";
      setSessionVariables = true;
    };

    programs.home-manager.enable = true;
    # Do not change this value. It defines the state version for compatibility.
    home.stateVersion = "23.11"; 
  };
}
