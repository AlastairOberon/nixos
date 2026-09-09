-- Define your variables (Make sure terminal, fileManager, and menu are defined here or earlier in the file)
local mainMod = "SUPER"

local terminal = "ghostty"
local fileManager = "thunar"
-- local menu = "hyprctl dispatch global quickshell:toggle_launcher"
local menu = "rofi -show drun"

-- HyprEnv Tools
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + CTRL + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
-- hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("hyprexpo:expo toggle"))

-- Example binds
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + DELETE", hl.dsp.exit())
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprctl dispatch pseudo")) -- dwindle
-- hl.bind(mainMod .. " + T", hl.dsp.togglesplit()) -- dwindle
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.exec_cmd("hyprctl dispatch togglesplit"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("rofi -show emoji -modi emoji"))

-- Extra App Keybinds (Note: double quotes inside the string are escaped with \ )
hl.bind("SUPER + V", hl.dsp.exec_cmd("rofi -modi clipboard:~/.local/bin/cliphist-rofi-img -show clipboard -show-icons -theme-str 'window {width: 60%;} element-icon {size: 5ch;} listview {lines: 10; columns: 1;} element {padding: 8px;} * {font: \"sans-serif 14\";}'"))

-- Switch workspaces & Move active window to workspace (Using a Lua loop!)
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Handle workspace 10 (since the '0' key maps to 10)
hl.bind(mainMod .. " + 0", hl.dsp.exec_cmd("hyprctl dispatch workspace 10"))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace 10"))

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Shift focus left/right between columns (scrolling the viewport)
hl.bind(mainMod .. " + mouse_down", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + mouse_up", hl.dsp.layout("move -col"))

-- 2. Focus windows (Moves focus and wraps around at the edges)
hl.bind(mainMod .. " + left", hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + right", hl.dsp.layout("focus r"))

-- 3. Move windows around (Swap current column with neighbors)
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))

-- 4. Manage stacked windows inside columns
-- Move the current window out into its own dedicated column
--hl.bind(mainMod .. " + P", hl.dsp.layout("promote"))
-- Consume: moves the window into the previous column
--hl.bind(mainMod .. " + C", hl.dsp.layout("consume"))
-- Expel: pushes the window out of a stack into a new column
--hl.bind(mainMod .. " + E", hl.dsp.layout("expel"))

-- 5. Resize Columns
-- Cycles through your 'explicit_column_widths' (default: 1/3, 1/2, 2/3, full screen)
hl.bind(mainMod .. " + bracketleft", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + CTRL + mouse_down", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + CTRL + mouse_up", hl.dsp.layout("colresize +conf"))


-- Physically swap windows between columns
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg swapcol l"))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg swapcol r"))

-- If multiple windows are stacked in a single column, pop the active one into its own dedicated column
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg promote"))


-- Scroll through existing workspaces
--hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + tab", hl.dsp.focus({ workspace = "e+1" }))
--hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
-- (Using bindm for mouse dragging actions)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys (Modifiers are omitted entirely if not needed)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"))

-- Requires playerctl 
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
