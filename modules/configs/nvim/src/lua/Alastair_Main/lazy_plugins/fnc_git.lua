return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add = { text = "│" },
            change = { text = "│" },
            delete = { text = "_" },
            topdelete = { text = "‾" },
            changedelete = { text = "~" },
            untracked = { text = "┆" },
        },
        on_attach = function(bufnr)
            local gs = package.loaded.gitsigns

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            -- Navigation between git hunks
            map("n", "]c", function()
                if vim.wo.diff then
                    return "]c"
                end
                vim.schedule(function()
                    gs.next_hunk()
                end)
                return "<Ignore>"
            end, { expr = true, desc = "Next git hunk" })

            map("n", "[c", function()
                if vim.wo.diff then
                    return "[c"
                end
                vim.schedule(function()
                    gs.prev_hunk()
                end)
                return "<Ignore>"
            end, { expr = true, desc = "Previous git hunk" })

            -- Actions
            map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
            map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
            map("v", "<leader>hs", function()
                gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, { desc = "Stage selected hunk" })
            map("v", "<leader>hr", function()
                gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, { desc = "Reset selected hunk" })

            map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage whole buffer" })
            map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo staged hunk" })
            map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset whole buffer" })
            map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk diff" })
            map("n", "<leader>gb", function()
                gs.blame_line({ full = true })
            end, { desc = "Blame line (full)" })
            map("n", "<leader>ub", gs.toggle_current_line_blame, { desc = "Toggle inline git blame" })
            map("n", "<leader>hd", gs.diffthis, { desc = "Diff against index" })
        end,
    },
}
