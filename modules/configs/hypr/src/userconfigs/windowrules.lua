-- =========================================================================
-- Dynamic 16:9 Floating Window Sizing
-- Ratio: 16:9
-- Rule: The height or width of the floating window is two-thirds (66.7%)
-- of the screen dimension depending on which screen dimension is shorter.
-- Automatically adapts to any monitor resolution.
-- =========================================================================

local function get_screen_resolution()
    -- 1. Direct sysfs check for connected eDP/HDMI/DP display modes (fastest & no subprocess IPC deadlock)
    for _, path in ipairs({
        "/sys/class/drm/card1-eDP-1/modes",
        "/sys/class/drm/card0-eDP-1/modes",
        "/sys/class/drm/card1-HDMI-A-1/modes",
        "/sys/class/drm/card0-HDMI-A-1/modes",
        "/sys/class/drm/card1-DP-1/modes",
        "/sys/class/drm/card0-DP-1/modes"
    }) do
        local f = io.open(path, "r")
        if f then
            local line = f:read("*l")
            f:close()
            if line then
                local w, h = line:match("(%d+)x(%d+)")
                if w and h then
                    return tonumber(w), tonumber(h)
                end
            end
        end
    end

    -- 2. Fallback to querying first available connected mode via sysfs
    local p = io.popen("head -n 1 /sys/class/drm/*/modes 2>/dev/null | grep -E '^[0-9]+x[0-9]+' | head -n 1", "r")
    if p then
        local line = p:read("*l")
        p:close()
        if line then
            local w, h = line:match("(%d+)x(%d+)")
            if w and h then
                return tonumber(w), tonumber(h)
            end
        end
    end

    -- 3. Fallback to primary internal display resolution (2560x1600)
    return 2560, 1600
end

local screen_w, screen_h = get_screen_resolution()

local win_w, win_h
if screen_w < screen_h then
    -- Portrait screen: width is shorter
    win_w = math.floor((2 / 3) * screen_w + 0.5)
    win_h = math.floor(win_w * (9 / 16) + 0.5)
else
    -- Landscape screen: height is shorter
    win_h = math.floor((2 / 3) * screen_h + 0.5)
    win_w = math.floor(win_h * (16 / 9) + 0.5)
end

local size_16_9 = { tostring(win_w), tostring(win_h) }

-- Global rule: prevent maximize greediness
hl.window_rule({
    name = "greedyApps",
    match = { class = ".*" },
    suppress_event = "maximize"
})

-- Default 16:9 size and centering for all floating application windows
hl.window_rule({
    name   = "default_floating_size_16_9",
    match  = { float = true },
    size   = size_16_9,
    center = true,
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name        = "xWaylandFix",
    match       = {
        class       = "^$",
        title       = "^$",
        xwayland    = true,
        float       = true,
        fullscreen  = false,
        pin         = false,
    },
    no_focus    = true,
})

-- =========================================================================
-- Floating Application Window Rules (16:9 Aspect Ratio)
-- =========================================================================

-- BlueTooth Manager (OverSkride)
hl.window_rule({
    name    = "init_OverSkride",
    match   = { class = "io.github.kaii_lb.Overskride" },
    size    = size_16_9,
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- Waypaper (Wallpaper Manager)
hl.window_rule({
    name    = "init_waypaper",
    match   = { class = "waypaper" },
    size    = size_16_9,
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- BlenderLauncher
hl.window_rule({
    name    = "init_BlenderLauncher",
    match   = { class = "blenderlauncher" },
    size    = size_16_9,
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- BlenderLauncher File View Dialog
hl.window_rule({
    name    = "init_BlenderLauncher_FileView",
    match   = { class = "blenderlauncher", title = "File View" },
    size    = size_16_9,
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- Thunar (File Manager)
hl.window_rule({
    name    = "init_Thunar",
    match   = { class = "thunar" },
    size    = size_16_9,
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- MPV (Video Player)
hl.window_rule({
    name    = "init_mpv",
    match   = { class = "mpv" },
    size    = size_16_9,
    float   = true,
    center  = true,
})

-- VLC (Media Player)
hl.window_rule({
    name    = "init_vlc",
    match   = { class = "vlc" },
    size    = size_16_9,
    float   = true,
    center  = true,
})

-- IMV (Image Viewer)
hl.window_rule({
    name    = "init_imv",
    match   = { class = "imv" },
    size    = size_16_9,
    float   = true,
    center  = true,
})

-- Ymuse (Music Player)
hl.window_rule({
    name    = "init_ymuse",
    match   = { class = "ymuse" },
    size    = size_16_9,
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- EasyEffects (Audio Management)
hl.window_rule({
    name    = "init_easyeffects",
    match   = { class = "com.github.wwmm.easyeffects" },
    size    = size_16_9,
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- Calibre E-Book Reader & Library
hl.window_rule({
    name    = "init_calibre",
    match   = { class = "calibre-gui" },
    size    = size_16_9,
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- Prism Launcher
hl.window_rule({
    name    = "init_prismlauncher",
    match   = { class = "org.prismlauncher.PrismLauncher" },
    size    = size_16_9,
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- Zenity Dialogs
hl.window_rule({
    name    = "init_Zenity",
    match   = { class = "zenity" },
    size    = size_16_9,
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- Common File Open/Save Dialogs
hl.window_rule({
    name   = "file_picker_dialogs",
    match  = { title = "^(Open File|Save File|Open Folder|Save As|Choose Files)$" },
    size   = size_16_9,
    float  = true,
    center = true,
})

-- XDG Desktop Portal Dialogs & Screen Share Pickers
hl.window_rule({
    name   = "portal_dialogs",
    match  = { class = "(xdg-desktop-portal-.*)" },
    size   = size_16_9,
    float  = true,
    center = true,
})

-- =========================================================================
-- Specialized Window Rules
-- =========================================================================

-- Steam Friends List (keep compact narrow buddy list)
hl.window_rule({
    name    = "init_SteamFloat",
    match   = {
        class = "^(steam)$",
        title = "^(Friends List)$"
    },
    size    = { "20%", "44%" },
    float   = true,
    center  = true,
    opacity = 0.85,
})

-- Picture in Picture (keep compact, pinned)
hl.window_rule({
    name        = "init_PicInPic",
    match       = { title = "Picture-in-Picture" },
    float       = true,
    pin         = true,
    rounding    = 0,
    opaque      = true,
})

-- Spotify
hl.window_rule({
    name    = "init_Spotify",
    match   = { class = "Spotify" },
    opacity = 0.85,
})

-- Rofi
hl.window_rule({
    name    = "init_Rofi",
    match   = { class = "Rofi" },
    opacity = 0.85,
})

-- =========================================================================
-- Layer Rules
-- =========================================================================

-- Disable Quickshell animations (prevents zoom/flicker)
hl.layer_rule({
    name    = "disable_quickshell_animations",
    match   = { namespace = "quickshell" },
    no_anim = true,
})

-- Power Menu Blur
hl.layer_rule({
    name         = "init_powermenu_blur",
    match        = { namespace = "power-menu" },
    blur         = true,
    ignore_alpha = 0.0,
    no_anim      = true,
})

-- Shortcuts Menu Blur & Animation Fix
hl.layer_rule({
    name         = "init_shortcutsmenu_blur",
    match        = { namespace = "shortcuts-menu" },
    blur         = true,
    ignore_alpha = 0.0,
    no_anim      = true,
})

-- Launcher Blur & Animation Fix
hl.layer_rule({
    name         = "init_launcher_blur",
    match        = { namespace = "qs-launcher" },
    blur         = true,
    ignore_alpha = 0.0,
    no_anim      = true,
})

-- Blur all Quickshell bars and attached popups
hl.layer_rule({
    name         = "blur_quickshell_main",
    match        = { namespace = "quickshell" },
    blur         = true,
    blur_popups  = true,
    ignore_alpha = 0.0,
})

