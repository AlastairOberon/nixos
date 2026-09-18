-- Optional display calibration profile (applied only if present on this device)
local icc_path = "/home/alastair_oberon/.local/share/icc/TPLCD_1600_Native_HDR.icm"
local icc_file = io.open(icc_path, "r")
local icc_arg = nil
if icc_file then
    icc_file:close()
    icc_arg = icc_path
end

-- Primary Internal Display (Lenovo Legion 5 Pro 16:10 2560x1600 @ 165Hz)
hl.monitor({
    output      = "eDP-1",
    mode        = "highres@highrr",
    icc         = icc_arg,
    position    = "0x0",
    scale       = 1,
    vrr         = 1
})

-- Dynamic fallback for external monitors (HDMI / USB-C DisplayPort)
hl.monitor({
    output      = "",
    mode        = "preferred",
    position    = "auto",
    scale       = 1
})

