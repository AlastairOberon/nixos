-- Cursors
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_SIZE", "24")

-- Hardware / GPU Ordering:
-- For hybrid laptops with multiple DRM cards, order iGPU first to drive the display.
-- On single-GPU systems or desktops, Aquamarine automatically manages card selection.
local card1 = io.open("/dev/dri/card1", "r")
local card0 = io.open("/dev/dri/card0", "r")
if card1 and card0 then
    card1:close()
    card0:close()
    hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card0")
else
    if card1 then card1:close() end
    if card0 then card0:close() end
end

-- Wayland Desktop Standards
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Toolkit Backend Preferences
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Screenshots
hl.env("HYPRSHOT_DIR", "Pictures/Screenshots")

