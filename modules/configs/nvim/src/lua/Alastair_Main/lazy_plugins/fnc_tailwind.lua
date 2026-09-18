return {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
        "roobert/tailwindcss-colorizer-cmp.nvim",
    },
    config = function()
        local colorizer = require("colorizer")
        local tailwind_colorizer = require("tailwindcss-colorizer-cmp")

        colorizer.setup({
            filetypes = { "html", "css", "javascript", "typescript", "javascriptreact", "typescriptreact", "vue", "svelte" },
            user_default_options = {
                tailwind = true,
                RGB = true,
                RRGGBB = true,
                names = false,
                RRGGBBAA = true,
                rgb_fn = true,
                hsl_fn = true,
                css = true,
                css_fn = true,
            },
        })

        tailwind_colorizer.setup({
            color_square_width = 2,
        })
    end,
}

