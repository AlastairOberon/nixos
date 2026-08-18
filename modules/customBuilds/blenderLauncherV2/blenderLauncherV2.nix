{ pkgs, ... }:

let
  version = "2.7.6";

  # 1. Download and extract the raw binary
  blender-launcher-bin = pkgs.stdenv.mkDerivation {
    pname = "blender-launcher-v2-bin";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/Victor-IX/Blender-Launcher-V2/releases/download/v${version}/Blender_Launcher_v${version}_Ubuntu_x64.zip";
      sha256 = "72a6d00bc16d8e7940f6c7449e3b5553607a7232e0609d3b97193b02f7b2ec89";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    sourceRoot = ".";

    installPhase = ''
      # Create an /opt directory to hold all the extracted files together
      mkdir -p $out/opt/blender-launcher
      cp -r ./* $out/opt/blender-launcher/
      
      mkdir -p $out/bin
      
      # Recursively search for any executable starting with 'Blender' (ignoring .so files)
      EXECUTABLE=$(find $out/opt/blender-launcher -type f -executable -name "Blender*" ! -name "*.so*" | head -n 1)
      
      # Failsafe: If it STILL can't find it, crash and print the entire folder contents to the log
      if [ -z "$EXECUTABLE" ]; then
        echo "ERROR: Could not find the executable! Here is what was extracted:"
        find $out/opt/blender-launcher
        exit 1
      fi
      
      # Link the found executable
      ln -s "$EXECUTABLE" $out/bin/blender-launcher-raw
    '';
  };
in
# 2. Wrap it in a virtual FHS sandbox so PyInstaller doesn't crash
pkgs.buildFHSEnv {
  name = "blenderlauncher"; # This will be the terminal command
  
  targetPkgs = pkgs: (with pkgs; [
    # Standard libraries expected by the PyInstaller binary
    zlib
    glib
    fontconfig
    freetype
    libGL
    libxkbcommon
    dbus
    
    # Updated package names for nixos-unstable
    libx11
    libxcb
    libxcb-wm
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    wayland
    libxcb-cursor
    xkeyboard_config
  ]);

  # Inject environment variables before the app starts (Fixes Fonts & Keyboard)
  profile = ''
    export XKB_CONFIG_ROOT=${pkgs.xkeyboard_config}/share/X11/xkb
    export FONTCONFIG_FILE=/etc/fonts/fonts.conf
  '';

  # THE FIX: A script that copies the app to a writable directory before launching
  runScript = pkgs.writeShellScript "blender-launcher-start" ''
    WORK_DIR="$HOME/.local/share/BlenderLauncher-Nix"
    
    # 1. Clean up the old writable copy and create a fresh one from the Nix store
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    
    # 2. Copy the binary and make it fully writable
    cp -rL ${blender-launcher-bin}/opt/blender-launcher/* "$WORK_DIR/"
    chmod -R +w "$WORK_DIR"
    
    # 3. Find and run the writable executable
    EXECUTABLE=$(find "$WORK_DIR" -type f -executable -name "Blender*" ! -name "*.so*" | head -n 1)
    exec "$EXECUTABLE" "$@"
  '';

  # 3. Create a desktop entry for Rofi
  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cat <<EOF > $out/share/applications/blenderlauncher.desktop
    [Desktop Entry]
    Name=Blender Launcher V2
    Exec=blenderlauncher
    Type=Application
    Categories=Graphics;3DGraphics;
    EOF
  '';
}
