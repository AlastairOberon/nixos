-- 1. Environment variables first (ensures child processes and plugins inherit them)
require("userconfigs.env_var")

-- 2. Hardware and Autostart
require("userconfigs.monitors")
require("userconfigs.auto_exec")

-- 3. Visuals & Layout
require("userconfigs.look")
require("userconfigs.animations")
require("userconfigs.layout")

-- 4. Rules, Input & Keybinds
require("userconfigs.windowrules")
require("userconfigs.input")
require("userconfigs.keybinds")

-- 5. Plugins
require("userconfigs.plugins")

