-- Create a table for our colors with fallbacks
local colors = { background = "#000000", color0 = "#222222", color4 = "#33ccff", color10 = "#00ff99" }

-- Natively parse your EXISTING Pywal .conf file
local file = io.open(os.getenv("HOME") .. "/.cache/wal/colors-hyprland.conf", "r")
if file then
    for line in file:lines() do
        -- This regex looks for "$variable = value" and pulls them out
        local k, v = line:match("%$([%w_]+)%s*=%s*(.+)")
        if k and v then
            colors[k] = v
        end
    end
    file:close()
end

hl.config({
    general = {
        gaps_in                     = 5,
        gaps_out                    = 10,
        border_size                 = 2,

        -- The Hyprland API expects the exact string key "col.active_border" here
        ["col.active_border"]       = {
            colors = { colors.color4, colors.color10 },
            angle = 90
        },

        ["col.inactive_border"]     = colors.color0,

        resize_on_border            = true,
        allow_tearing               = false,
        layout                      = "scrolling"
    },

    decoration = {
        rounding            = 15,
        rounding_power      = 2,
        active_opacity      = 1.0,
        inactive_opacity    = 0.6,

        shadow = {
            enabled         = true,
            range           = 4,
            render_power    = 3,
            color           = colors.background
        },

        blur = {
            enabled     = false,
            size        = 3,
            passes      = 2,
            vibrancy    = 0.1696
        }
    }
})
