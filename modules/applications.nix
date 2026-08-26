{ pkgs, inputs, ... }:

{
    programs.hyprland.enable = true;
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    programs.dconf.enable = true;
    services.netbird.enable = true;
    services.passSecretService.enable = true;

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

        #CLI
        ghostty
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
        yt-dlp
        wget
        tree
        imagemagick
        snapper
        exiftool
        cliamp

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
    ];
}
