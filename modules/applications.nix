{ pkgs, inputs, ... }:

{
    imports = [
        ./flake/zenBrowser.nix
        ./flake/alcom.nix
        ./flake/unityHub.nix
        ./flake/podman.nix
        ./customBuilds/customBuilds.nix
    ];

    programs.hyprland.enable = true;
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    programs.dconf.enable = true;

    environment.systemPackages = with pkgs; [
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
        # Hyprland Ecosystem & GUI Apps
        hyprpaper
        hyprlock
        hyprshot
        waypaper
        rofi
        cliphist
        firefox
        thunar
        vesktop
        calibre
        inkscape
        obs-studio
        vlc
        mpv
        qbittorrent
        retroarch
        easyeffects
        quickshell
        qt6.qtwayland
        qt6.qtdeclarative
        gnome-themes-extra
        adwaita-icon-theme
        nwg-look
        imagemagick
        stow

        # CLI & Terminal Utilities
        ghostty
        neovim
        micro
        git
        fzf
        fastfetch
        btop
        htop
        ripgrep
        yazi
        yt-dlp
        starship
        zoxide
        atuin
        wl-clipboard
        wget
        unzip
        zip
        btrfs-assistant
        snapper
        tree
        nodejs_22
        go
        python3
        gcc
        gopls
        uv
    ];
}
