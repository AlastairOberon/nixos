{ pkgs, inputs, ... }:

pkgs.hyprlandPlugins.mkHyprlandPlugin (finalAttrs: {
  pluginName = "hyprglass";
  version = "latest";
  
  src = inputs.hyprglass;

  meta = {
    homepage = "https://github.com/hyprnux/hyprglass";
    description = "Hyprglass plugin for Hyprland";
    license = pkgs.lib.licenses.bsd3;
    platforms = pkgs.lib.platforms.linux;
  };

  # 👇 Tell Nix how to install the file since the Makefile doesn't
  installPhase = ''
    mkdir -p $out/lib
    cp hyprglass.so $out/lib/
  '';
})
