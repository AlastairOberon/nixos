hl.plugin.load("/run/current-system/sw/lib/hyprglass.so")

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        enabled            = 1,
        manage_window_blur = 1,
        default_theme      = "dark",
        default_preset     = "voxel",
        layers             = { enabled = 1 },
    })

    -- Layer surfaces: Whitelist namespaces for glass shader rendering
    hg.layer("waybar", { preset = "subtle", mask_threshold = 0.05 })
    hg.layer("swaync")
    hg.layer("quickshell", { preset = "voxel", mask_threshold = 0.05 })
    hg.layer("qs-launcher", { preset = "voxel", mask_threshold = 0.05 })
    hg.layer("power-menu", { preset = "voxel", mask_threshold = 0.05 })
    hg.layer("shortcuts-menu", { preset = "voxel", mask_threshold = 0.05 })
    hg.layer("debug-panel", { exclude = true })

    -- =========================================================================
    -- PRESETS
    -- =========================================================================

    -- 1. "clear": Crisp, lightweight frosted glass
    hg.preset("clear", {
        glass_opacity = 0.85,
        blur_strength = 3.8,
        blur_iterations = 4,
        dark = { brightness = 0.85 },
        light = { brightness = 1.15 },
    })

    -- 2. "contrasted": High-contrast deep glass
    hg.preset("contrasted", {
        contrast      = 1.25,
        adaptive_dim  = 1.2,
        blur_strength = 4.5,
        dark          = { tint_color = 0x02142aa9 },
    })

    -- 3. "voxel": Flagship Liquid Glass (Silky smooth body diffusion & refined optical edges)
    hg.preset("voxel", {
        glass_opacity        = 1.0,

        -- 1. Body Blur & Smooth Diffusion
        blur_strength        = 5.2,       -- Generous Gaussian radius for rich, creamy body diffusion
        blur_iterations      = 5,         -- 5 passes eliminate banding and noise completely

        -- 2. Surface & Body Lighting
        fresnel_strength     = 0.50,      -- Clean edge rim lighting
        specular_strength    = 0.24,      -- Subtle top-down specular sheen across the upper body

        -- 3. Edge Optics & Controlled Refraction (leaves body text sharp and unwarped)
        edge_thickness       = 0.10,      -- Confines refraction warp strictly to the perimeter
        refraction_strength  = 0.95,      -- Clean optical glass bend
        lens_distortion      = 0.20,      -- Tamed center curvature to prevent bubble distortion
        chromatic_aberration = 0.35,      -- Subtle prism rainbow hint along edges

        -- 4. Color Vibrancy & Dynamic Range
        saturation           = 1.25,      -- Saturates background colors shining through the glass
        vibrancy             = 0.35,      -- Enhances vibrant tones in wallpapers/windows
        contrast             = 1.12,      -- Deepens shadows and keeps text crisp
        brightness           = 1.02,
        adaptive_dim         = 0.25,      -- Softly tones down intense background highlights

        dark = {
            brightness       = 1.18,      -- Retains rich, deep velvety dark tones
            saturation       = 1.30,
            vibrancy         = 0.40,
        },
        light = {
            brightness       = 1.05,
            contrast         = 1.15,
        }
    })

    -- 4. "velvet": Ultra-smooth, milky matte frost with minimal distortion
    hg.preset("velvet", {
        glass_opacity        = 0.96,
        blur_strength        = 6.5,
        blur_iterations      = 5,
        fresnel_strength     = 0.30,
        specular_strength    = 0.15,
        edge_thickness       = 0.06,
        refraction_strength  = 0.45,
        lens_distortion      = 0.10,
        chromatic_aberration = 0.18,
        saturation           = 1.20,
        vibrancy             = 0.30,
        contrast             = 1.08,
        brightness           = 1.05,
        dark = {
            brightness       = 1.12,
            saturation       = 1.25,
        }
    })
end

