{ pkgs, inputs, ... }:

{
    programs.nix-ld.enable = true;
    programs.hyprland.enable = true;
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    programs.dconf.enable = true;
    services.netbird.enable = true;
    services.passSecretService.enable = true;
    services.playerctld.enable = true;

    # Native NixOS systemd user service
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
        #Flake inputs
        inputs.spotx.packages.${pkgs.stdenv.hostPlatform.system}.spotify-spotx

        #Hardware
        brightnessctl
        playerctl
        wireplumber
        pass
        pkgs.lenovo-legion

        #Dev & Programming
        gcc
        gnumake
        git
        stow
        go
        gopls
        python3
        uv
        nodejs_22
        netbird-ui
        netbird
        openssl
        qrencode
        libnotify
        file
        vdirsyncer

        #CLI
        ghostty
        neovim
        micro
        fastfetch
        btop
        htop
        ripgrep
        aria2
        fzf
        zoxide
        starship
        atuin
        yt-dlp
        wget
        tree
        imagemagick
        snapper
        exiftool
        cliamp
        cava
        wiremix
        ani-cli
        wl-clipboard
        cliphist
        wayshot
        slurp
        grim
        libwebp
        gallery-dl
        satty
        spotify-player
        khal
        lazygit

        #hyprland
        hyprpaper
        hyprlock
        hyprshot
        hyprpolkitagent
        waypaper
        rofi
        cliphist
        wl-clipboard
        quickshell
        nwg-look
        adwaita-icon-theme
        gnome-themes-extra
        qt6.qtwayland
        qt6.qtdeclarative
        qt6.qt5compat

        #File Management
        engrampa
        btrfs-assistant
        zip
        unzip
        p7zip
        unrar
        xz
        zstd
        gzip
        bzip2
        gnutar
        file-roller

        #GUI
        firefox
        vesktop
        calibre
        inkscape
        obs-studio
        vlc
        mpv
        qbittorrent
        retroarch
        easyeffects
        overskride
        onlyoffice-desktopeditors
        prismlauncher
    ];
}
