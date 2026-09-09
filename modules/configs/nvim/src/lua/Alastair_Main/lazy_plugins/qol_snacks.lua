return{
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts ={
            explorer = {
                enabled = true,
                layout = {
                    cycle = true
                },
            },
            picker ={
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
                        reverse = true, -- set to false for search bar to be on top 
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

                }
            }
        } ,
        keys = {
            { "<leader>lg", function() require("snacks").lazygit() end, desc = "Lazygit" },
            { "<leader>gl", function() require("snacks").lazygit.log() end, desc = "Lazygit Logs" },
            { "<leader>es", function() require("snacks").explorer() end, desc = "Open Snacks Explorer" },
            { "<leader>dB", function() require("snacks").bufdelete() end, desc = "Delete or Close Buffer (Confirm)" },

            { "<leader>pf", function() require("snacks").picker.files() end, desc = "Pick Files" },
            { "<leader>pg", function() require("snacks").picker.grep() end, desc = "Grep Word" },
        },
        {
            "folke/todo-comments.nvim",
            event = {"BufReadPre", "BufNewFile"},
            keys = {
                { "<leader>pt", function() require("snacks").picker.todo_comments() end, desc = "All" },
                { "<leader>pT", function() require("snacks").picker.todo_comments({ keywords = { "TODO","FORGETNOT","FIXME" } }) end, desc = "mains" }, 
            },
        }

    }
}
