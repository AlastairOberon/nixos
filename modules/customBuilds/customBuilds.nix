# modules/custom-builds.nix
{ pkgs, inputs, ... }:

let
    # 1. Hyprglass
    pluginsHyprglass = import ./hyprlandPlugins/build_hyprglass.nix { inherit pkgs inputs; };

    # 2. Pywal with Haishoku
    pywalHaishoku = import ./pywal/build_pywal.nix { inherit pkgs; };

    # 3. Blender Launcher V2
    blenderLauncherV2 = import ./blenderLauncherV2/blenderLauncherV2.nix { inherit pkgs; };
in




{
    # Nix will automatically merge this list with the one in applications.nix!
    environment.systemPackages = [
        pluginsHyprglass
        pywalHaishoku
        blenderLauncherV2
    ];
}
