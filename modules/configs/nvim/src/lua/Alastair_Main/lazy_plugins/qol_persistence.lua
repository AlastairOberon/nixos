return {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
        need = 1,
    },
    keys = {
        {
            "<leader>qs",
            function()
                require("persistence").load()
            end,
            desc = "Restore current directory session",
        },
        {
            "<leader>ql",
            function()
                require("persistence").load({ last = true })
            end,
            desc = "Restore last session",
        },
        {
            "<leader>qd",
            function()
                require("persistence").stop()
            end,
            desc = "Don't save current session",
        },
    },
}
