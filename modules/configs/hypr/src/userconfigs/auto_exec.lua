hl.on("hyprland.start", function()
    -- 1. Synchronize Wayland environment with systemd & dbus FIRST
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")

    -- 2. Activate Hyprland session target (activates graphical-session.target for portals/screenshare)
    hl.exec_cmd("systemctl --user start hyprland-session.target")

    -- 3. Authentication & Clipboard
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("hyprctl setcursor Adwaita 24")

    -- 4. Wallpaper daemon & restoration
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waypaper --restore")

    -- 5. Quickshell Desktop Environment
    hl.exec_cmd("QT_SCALE_FACTOR=1 qs")
end)

