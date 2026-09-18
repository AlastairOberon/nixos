{ pkgs, inputs, ... }:

{
  programs.nix-ld.enable = true;
  programs.hyprland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  programs.dconf.enable = true;
  services.netbird.enable = true;
  services.passSecretService.enable = true;
  services.playerctld.enable = true;

  # Native NixOS systemd user service for CalDAV synchronization
  systemd.user.services.vdirsyncer = {
    description = "Synchronize CalDAV calendars";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
    };
  };

  systemd.user.timers.vdirsyncer = {
    description = "Timer for vdirsyncer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "15m";
      Unit = "vdirsyncer.service";
    };
  };

  environment.systemPackages = with pkgs; [
    # --- Flake Inputs & Patched Packages ---
    inputs.spotx.packages.${pkgs.stdenv.hostPlatform.system}.spotify-spotx

    # --- Hardware & Power Management ---
    brightnessctl
    playerctl
    wireplumber

    # --- Desktop Environment & Hyprland Ecosystem ---
    hyprpaper
    hyprlock
    hyprshot
    hyprpolkitagent
    waypaper
    rofi
    quickshell
    nwg-look

    # --- Wayland & Screen Capture Utilities ---
    wl-clipboard
    cliphist
    wayshot
    slurp
    grim
    satty

    # --- Terminal Emulators ---
    ghostty

    # --- CLI Utilities & Text Editors ---
    neovim
    micro
    fastfetch
    btop
    htop
    ripgrep
    fzf
    zoxide
    starship
    atuin
    tree
    file
    pass
    lazygit
    mpd
    mpc
    ncmpcpp

    # --- Development, Compilers & Languages ---
    gcc
    gnumake
    git
    go
    gopls
    python3
    uv
    nodejs_22
    openssl
    qrencode
    libnotify
    nil
    statix
    nixfmt

    # --- Networking, VPN & Remote ---
    netbird
    netbird-ui

    # --- Terminal Media, Audio & Downloaders ---
    spotify-player
    cliamp
    cava
    wiremix
    ani-cli
    yt-dlp
    gallery-dl
    aria2
    wget
    imagemagick
    libwebp
    exiftool

    # --- Calendar & Personal Information Sync ---
    khal
    vdirsyncer

    # --- Archive & Compression Tools ---
    zip
    unzip
    p7zip
    unrar
    xz
    zstd
    gzip
    bzip2
    gnutar
    engrampa
    file-roller

    # --- Desktop GUI Applications ---
    # firefox # Pruned: Zen Browser is primary browser (managed in modules/flake/zenBrowser.nix)
    vesktop
    calibre
    inkscape
    obs-studio
    vlc
    mpv
    imv
    zathura
    qbittorrent
    retroarch
    easyeffects
    overskride
    onlyoffice-desktopeditors
    prismlauncher
    antigravity-ide
    ymuse

    # --- Theming, Icons & Qt/GTK Compatibility ---
    adwaita-icon-theme
    gnome-themes-extra
    qt6.qtwayland
    qt6.qtdeclarative
    qt6.qt5compat
  ];
}
