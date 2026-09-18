# Holding Directory for Flake Modules

Any `.nix` file placed inside this directory is **completely ignored** by your NixOS system build.

### How to use this folder:
- **To park / disable a heavy app**:
  Move the file into this folder:
  ```bash
  mv /etc/nixos/modules/flake/affinity.nix /etc/nixos/modules/flake/holding/
  ```
  *(Remember to also remove or comment out `./affinity.nix` in `modules/flake/default.nix` if it was listed there)*.

- **To restore an app**:
  Move it back out to `modules/flake/`:
  ```bash
  mv /etc/nixos/modules/flake/holding/affinity.nix /etc/nixos/modules/flake/
  ```
  and add `./affinity.nix` to `modules/flake/default.nix`.
