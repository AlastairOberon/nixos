return {
    {
        "folke/zen-mode.nvim",
        cmd = "ZenMode",
        opts = {
            window = {
                backdrop = 0.95,
                width = 85,
                height = 1,
                options = {
                    signcolumn = "no",
                    number = false,
                    relativenumber = false,
                    cursorline = false,
                    cursorcolumn = false,
                    foldcolumn = "0",
                    list = false,
                },
            },
            plugins = {
                options = {
                    enabled = true,
                    ruler = false,
                    showcmd = false,
                    laststatus = 0,
                },
                twilight = { enabled = true },
                gitsigns = { enabled = false },
            },
        },
        keys = {
            { "<leader>z", "<cmd>ZenMode<CR>", desc = "Toggle Zen Writing Mode" },
            { "<leader>uz", "<cmd>ZenMode<CR>", desc = "Toggle Zen Mode" },
        },
    },
    {
        "folke/twilight.nvim",
        cmd = { "Twilight", "TwilightEnable", "TwilightDisable" },
        opts = {
            dimming = {
                alpha = 0.35,
            },
            context = 10,
            treesitter = true,
        },
        keys = {
            { "<leader>uT", "<cmd>Twilight<CR>", desc = "Toggle Twilight Focus" },
        },
    },
}
