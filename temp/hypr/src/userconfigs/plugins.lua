hl.plugins = {
    "/run/current-system/sw/lib/hyprglass.so"
}

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        enabled = 1,
        manage_window_blur = 1,
        default_theme = "dark",
        default_preset = "voxel",


        --brightness = 0.9,
        --dark = { brightness = 0.82 },
        --light = { adaptive_boost = 0.5 },

        layers = { enabled = 1 },
    })

    -- Layer surfaces: each call whitelists the namespace and configures it
    hg.layer("waybar", { preset = "subtle", mask_threshold = 0.05 })
    hg.layer("swaync")
    hg.layer("quickshell", { preset = "voxel", mask_threshold = 0.05 })
    -- hg.layer("quickshell:bezel", { preset = "ui", mask_threshold = 0.3 })
    hg.layer("debug-panel", { exclude = true })

    -- Presets
    hg.preset("clear", {
        glass_opacity = 0.8,
        blur_strength = 3.5,
        dark = { brightness = 0.7 },
        light = { brightness = 1.2 },
    })

    hg.preset("contrasted", {
        inherits = "high_contrast",
        contrast = 1.2,
        adaptive_dim = 1.5,
        dark = { tint_color = 0x02142aa9 },
    })
    hg.preset("voxel", {
        glass_opacity = 1.0,
        fresnel_strength = 0.4,     -- Slightly softer edge-lighting
        specular_strength = 0.0,    -- Keep center clean
        blur_strength = 1.5,
        blur_iterations = 6,
        -- ==========================================
        -- 3. CONTROLLED EDGE WARP (Tame in the middle)
        -- ==========================================
        edge_thickness = 0.07,      -- (Was 0.4) Narrows the warping zone so it hugs only the very perimeter!
        refraction_strength = 1.0,  -- (Was 1.8) A cleaner, less aggressive bend
        lens_distortion = 0.7,      -- (Was 1.2) Drastically reduces the middle-magnification effect
        chromatic_aberration = 0.4, -- (Was 1.5) Softens the rainbow prism effect to a subtle, clean hint
        -- 4. Color Balance
        contrast = 1.2,
        brightness = 1.05,
        dark = {
            brightness = 1.4
        }
    })
end
