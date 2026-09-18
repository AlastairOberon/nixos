# /etc/nixos/modules/flake/holding.nix
# =========================================================================
# PARKED / HELD FLAKES & HEAVY APPS
# =========================================================================
# This file is a holding bay. It is NOT imported by your NixOS system build.
# Anything listed here will NEVER be downloaded, compiled, or installed.
#
# To activate any of these apps on this machine:
# Simply move or copy its line into /etc/nixos/modules/flake/default.nix
# =========================================================================
{ ... }:

{
  imports = [
    ./affinity.nix   # Affinity Creative Suite (Heavy Wine prefix + multi-GB download)
    # ./herdr.nix      # Herdr AI Agent (Compiles from source: Zig, C, Ghostty VT)
    # ./unityHub.nix   # Unity Hub (Heavy proprietary Electron engine manager)
  ];
}
