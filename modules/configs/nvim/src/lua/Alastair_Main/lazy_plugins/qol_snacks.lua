return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        scratch = { enabled = true },
        explorer = {
            enabled = true,
            layout = {
                cycle = true,
            },
        },
        picker = {
            enabled = true,
            matchers = {
                frecency = true,
                cwd_bonus = true,
            },
            formatters = {
                file = {
                    filename_first = false,
                    filename_only = false,
                    icon_width = 2,
                },
            },
            layout = {
                preset = "telescope",
                cycle = true,
            },
            layouts = {
                select = {
                    preview = false,
                    layout = {
                        backdrop = false,
                        width = 0.6,
                        min_width = 80,
                        height = 0.4,
                        min_height = 10,
                        box = "vertical",
                        border = "rounded",
                        title = "{title}",
                        title_pos = "center",
                        { win = "input", height = 1, border = "bottom" },
                        { win = "list", border = "none" },
                        { win = "preview", title = "{preview}", width = 0.6, height = 0.4, border = "top" },
                    },
                },
                telescope = {
                    reverse = true,
                    layout = {
                        box = "horizontal",
                        backdrop = false,
                        width = 0.8,
                        height = 0.9,
                        border = "none",
                        {
                            box = "vertical",
                            { win = "list", title = " Results ", title_pos = "center", border = "rounded" },
                            { win = "input", height = 1, border = "rounded", title = "{title} {live} {flags}", title_pos = "center" },
                        },
                        {
                            win = "preview",
                            title = "{preview:Preview}",
                            width = 0.50,
                            border = "rounded",
                            title_pos = "center",
                        },
                    },
                },
            },
        },
    },
    keys = {
        -- Git & Terminal
        { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
        { "<leader>lg", function() Snacks.lazygit() end, desc = "Lazygit" },
        { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Logs" },

        -- Explorer & Buffers
        { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
        { "<leader>es", function() Snacks.explorer() end, desc = "Open Snacks Explorer" },
        { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
        { "<leader>dB", function() Snacks.bufdelete() end, desc = "Delete Buffer (Confirm)" },

        -- Pickers: Files & Search
        { "<leader>pf", function() Snacks.picker.files() end, desc = "Find Files" },
        { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
        { "<leader>pg", function() Snacks.picker.grep() end, desc = "Grep (Search in Project)" },
        { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep (Search in Project)" },
        { "<leader>pr", function() Snacks.picker.recent() end, desc = "Recent Files" },
        { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent Files" },
        { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Find Buffers" },
        { "<leader>pWs", function() Snacks.picker.grep_word() end, desc = "Grep Word Under Cursor" },
        { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Grep Word Under Cursor" },
        { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Search Diagnostics" },
        { "<leader>pt", function() Snacks.picker.todo_comments() end, desc = "Search All Todos" },
        { "<leader>pT", function() Snacks.picker.todo_comments({ keywords = { "TODO", "FORGETNOT", "FIXME" } }) end, desc = "Search Main Todos" },

        -- Quick Notes / Scratchpad
        { "<leader>ns", function() Snacks.scratch() end, desc = "Toggle Note Scratchpad" },
        { "<leader>sn", function() Snacks.scratch() end, desc = "Toggle Note Scratchpad" },
        { "<leader>nS", function() Snacks.scratch.select() end, desc = "Select Scratchpad Note" },
    },
}
