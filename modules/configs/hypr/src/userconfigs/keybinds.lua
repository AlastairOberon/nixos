-- Define your variables
local mainMod = "SUPER"

local terminal = "ghostty"

local fileManager = "thunar"
local menu = "rofi -show drun"

-- Hyprlock & Session
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock"))

-- Screenshot Controls
-- Capture Full Output to WebP + clipboard
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd([[bash -c 'mkdir -p ~/Pictures/Screenshots; FILE=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).webp; grim - | tee >(wl-copy) | cwebp -lossless -o "$FILE" -- -; notify-send -a "Screenshot" "Screenshot Saved" "Output copied" -i "$FILE"']]))
-- Capture Selected Region to WebP + clipboard
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd([[bash -c 'mkdir -p ~/Pictures/Screenshots; GEOM=$(slurp); if [ -n "$GEOM" ]; then FILE=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).webp; grim -g "$GEOM" - | tee >(wl-copy) | cwebp -lossless -o "$FILE" -- -; notify-send -a "Screenshot" "Screenshot Saved" "Region copied" -i "$FILE"; fi']]))

-- Core App Launches
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + space",  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + C",      hl.dsp.exec_cmd("rofi -show emoji -modi emoji"))

-- Clipboard History (using system cliphist-rofi-img)
hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("rofi -modi clipboard:cliphist-rofi-img -show clipboard -show-icons"))

-- Window Management
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + DELETE",    hl.dsp.exit())
hl.bind(mainMod .. " + F",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + M",         hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pseudo())


-- Workspaces Navigation (1 - 10)
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special Scratchpad Workspace
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scrolling Layout: Column Viewport & Focus (Arrow Keys + Vim Keys)
hl.bind(mainMod .. " + mouse_down", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.layout("move -col"))

hl.bind(mainMod .. " + left",  hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + right", hl.dsp.layout("focus r"))
hl.bind(mainMod .. " + H",     hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + L",     hl.dsp.layout("focus r"))

-- Move between stacked windows inside a column
hl.bind(mainMod .. " + up",   hl.dsp.layout("focus u"))
hl.bind(mainMod .. " + down", hl.dsp.layout("focus d"))
hl.bind(mainMod .. " + K",    hl.dsp.layout("focus u"))
hl.bind(mainMod .. " + J",    hl.dsp.layout("focus d"))

-- Scrolling Layout: Swap Columns
hl.bind(mainMod .. " + SHIFT + left",   hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + SHIFT + right",  hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + SHIFT + H",      hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + SHIFT + L",      hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + SHIFT + comma",  hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))

-- Scrolling Layout: Column Stack Operations (Promote / Consume / Expel)
hl.bind(mainMod .. " + P",              hl.dsp.layout("promote")) -- Pop active window into its own column
hl.bind(mainMod .. " + ALT + H",        hl.dsp.layout("consume")) -- Consume window into previous column stack
hl.bind(mainMod .. " + ALT + left",     hl.dsp.layout("consume"))
hl.bind(mainMod .. " + ALT + L",        hl.dsp.layout("expel"))   -- Expel window out of stack into new column
hl.bind(mainMod .. " + ALT + right",    hl.dsp.layout("expel"))

-- Scrolling Layout: Column Resizing
hl.bind(mainMod .. " + bracketleft",         hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + bracketright",        hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + CTRL + mouse_down",   hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + CTRL + mouse_up",     hl.dsp.layout("colresize +conf"))

-- Workspace Cycling
hl.bind(mainMod .. " + tab",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "e-1" }))

-- Window Drag & Resize (Mouse)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop Multimedia Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"))

-- Media Controls
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"))

