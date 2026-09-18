return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local lint = require("lint")
        local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
        local eslint = lint.linters.eslint_d

        -- Map your filetypes to their respective linters
        lint.linters_by_ft = {
            javascript = { "biomejs" },
            typescript = { "biomejs" },
            javascriptreact = { "biomejs" },
            typescriptreact = { "biomejs" },
            svelte = { "biomejs" },
            python = { "pylint" },
            rust = { "clippy" },
            json = { "biomejs" },
            jsonc = { "biomejs" },
            yaml = { "yamllint" },
            markdown = { "markdownlint" },
            dockerfile = { "hadolint" },
            sh = { "shellcheck" },
            bash = { "shellcheck" },
            nix = { "statix" },
        }

        eslint.args = {
            "--no-warn-ignored",
            "--format",
            "json",
            "--stdin",
            "--stdin-filename",
            function()
                return vim.fn.expand("%:p")
            end,
        }

        local function safe_lint()
            local ft = vim.bo.filetype
            local linters = lint.linters_by_ft[ft] or {}
            local valid_linters = {}
            for _, name in ipairs(linters) do
                local linter = lint.linters[name]
                local cmd = (type(linter) == "table" and linter.cmd) or name
                if vim.fn.executable(cmd) == 1 then
                    table.insert(valid_linters, name)
                end
            end
            if #valid_linters > 0 then
                lint.try_lint(valid_linters)
            end
        end

        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            group = lint_augroup,
            callback = safe_lint,
        })

        vim.keymap.set("n", "<leader>cl", safe_lint, { desc = "Trigger linting for current file" })
        vim.keymap.set("n", "<leader>l", safe_lint, { desc = "Trigger linting for current file" })
    end,
}
