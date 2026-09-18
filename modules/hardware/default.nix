{ config, lib, pkgs, ... }:

let
  cfg = config.hardwareProfile;
in
{
  options.hardwareProfile = {
    # GPU profile selection
    gpu = {
      type = lib.mkOption {
        type = lib.types.enum [
          "auto"                 # Generic open-source Mesa/KMS (works on AMD, Intel, basic Nvidia/VM)
          "amd"                  # Dedicated or integrated AMD
          "intel"                # Intel GPU
          "nvidia"               # Dedicated Desktop NVIDIA (no PRIME)
          "nvidia-hybrid-amd"    # Laptop AMD iGPU + NVIDIA dGPU PRIME
          "nvidia-hybrid-intel"  # Laptop Intel iGPU + NVIDIA dGPU PRIME
        ];
        default = "auto";
        description = "GPU configuration profile";
      };

      nvidiaDriver = lib.mkOption {
        type = lib.types.enum [ "stable" "production" "beta" "legacy_580" "legacy_535" "legacy_470" "legacy_390" ];
        default = "stable";
        description = "NVIDIA driver package version";
      };

      open = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use open source kernel modules (RTX 20xx and newer; false for older like MX150)";
      };

      prime = {
        amdgpuBusId = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Bus ID of AMD integrated GPU (e.g. PCI:6:0:0)";
        };
        intelBusId = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Bus ID of Intel integrated GPU (e.g. PCI:0:2:0)";
        };
        nvidiaBusId = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Bus ID of NVIDIA dedicated GPU (e.g. PCI:1:0:0)";
        };
      };
    };

    # Device features
    laptop = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable power profiles daemon and mobile power optimizations";
      };
      lenovoLegion = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Lenovo Legion kernel module and GUI control app";
      };
      realtekWifiFix = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Disable ASPM L1 for rtw89 Realtek WiFi cards (RTL8852AE)";
      };
    };
  };

  config = lib.mkMerge [
    # Baseline configuration & hardware detection tool
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "nixos-hardware-detect" ''
          exec ${pkgs.python3}/bin/python3 /etc/nixos/bin/nixos-hardware-detect "$@"
        '')
        (pkgs.writeShellScriptBin "nixos-hardware-sync" ''
          exec ${pkgs.python3}/bin/python3 /etc/nixos/bin/nixos-hardware-sync "$@"
        '')
      ];
    }

    # Laptop power profiles
    (lib.mkIf cfg.laptop.enable {
      services.power-profiles-daemon.enable = true;
    })

    # Lenovo Legion specific
    (lib.mkIf cfg.laptop.lenovoLegion {
      boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];
      boot.kernelModules = [ "legion-laptop" ];
      environment.systemPackages = [ pkgs.lenovo-legion ];
    })

    # Realtek Wi-Fi latency fix
    (lib.mkIf cfg.laptop.realtekWifiFix {
      boot.extraModprobeConfig = ''
        options rtw89_core disable_aspm_l1=1 disable_aspm_l1ss=1
      '';
    })

    # AMD GPU configuration
    (lib.mkIf (cfg.gpu.type == "amd" || cfg.gpu.type == "nvidia-hybrid-amd") {
      boot.initrd.kernelModules = [ "amdgpu" ];
      environment.systemPackages = lib.mkIf (cfg.gpu.type == "amd") [ pkgs.nvtopPackages.amd ];
    })

    # Intel GPU configuration
    (lib.mkIf (cfg.gpu.type == "intel" || cfg.gpu.type == "nvidia-hybrid-intel") {
      boot.initrd.kernelModules = [ "i915" ];
      environment.systemPackages = lib.mkIf (cfg.gpu.type == "intel") [ pkgs.nvtopPackages.intel ];
    })

    # NVIDIA GPU configuration (Desktop or Laptop)
    (lib.mkIf (lib.hasPrefix "nvidia" cfg.gpu.type) {
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = cfg.laptop.enable;
        powerManagement.finegrained = (cfg.gpu.type == "nvidia-hybrid-amd" || cfg.gpu.type == "nvidia-hybrid-intel");
        open = cfg.gpu.open;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.${cfg.gpu.nvidiaDriver};

        prime = lib.mkIf (cfg.gpu.type == "nvidia-hybrid-amd" || cfg.gpu.type == "nvidia-hybrid-intel") {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          amdgpuBusId = lib.mkIf (cfg.gpu.type == "nvidia-hybrid-amd") cfg.gpu.prime.amdgpuBusId;
          intelBusId = lib.mkIf (cfg.gpu.type == "nvidia-hybrid-intel") cfg.gpu.prime.intelBusId;
          nvidiaBusId = cfg.gpu.prime.nvidiaBusId;
        };
      };

      environment.systemPackages = [ pkgs.nvtopPackages.full ];
    })
  ];
}
