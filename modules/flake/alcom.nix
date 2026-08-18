{ pkgs, ... }:

let
  # Fixes the blank WebKit window crash on NVIDIA + Wayland
  alcom-fixed = pkgs.symlinkJoin {
    name = "alcom-fixed";
    paths = [ pkgs.alcom ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Dynamically find and wrap the executable, regardless of its exact name
      for exe in $out/bin/*; do
        wrapProgram "$exe" \
          --set WEBKIT_DISABLE_DMABUF_RENDERER 1 \
          --set WEBKIT_DISABLE_COMPOSITING_MODE 1
      done
    '';
  };
in
{
  environment.systemPackages = [
    alcom-fixed
  ];
}
