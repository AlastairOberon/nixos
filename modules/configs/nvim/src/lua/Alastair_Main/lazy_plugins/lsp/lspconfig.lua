return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        { "antosha417/nvim-lsp-file-operations", config = true },
    },
    config = function()
        -- NOTE: LSP Keybinds
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                -- Buffer local mappings
                local opts = { buffer = ev.buf, silent = true }

                -- Keymaps
                opts.desc = "Show LSP references"
                vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

                opts.desc = "Go to declaration"
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

                opts.desc = "Show LSP definitions"
                vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

                opts.desc = "Show LSP implementations"
                vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

                opts.desc = "Show LSP type definitions"
                vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

                opts.desc = "See available code actions"
                vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
                vim.keymap.set({ "n", "v" }, "<leader>vca", vim.lsp.buf.code_action, opts)

                opts.desc = "Go to previous diagnostic"
                vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

                opts.desc = "Go to next diagnostic"
                vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

                opts.desc = "Smart rename"
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

                opts.desc = "Show buffer diagnostics"
                vim.keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

                opts.desc = "Show line diagnostics"
                vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

                opts.desc = "Show documentation for what is under cursor"
                vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

                opts.desc = "Restart LSP"
                vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

                vim.keymap.set("i", "<C-h>", function()
                    vim.lsp.buf.signature_help()
                end, opts)

                local client = vim.lsp.get_client_by_id(ev.data.client_id)
                if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
                    vim.keymap.set("n", "<leader>uh", function()
                        local current = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
                        vim.lsp.inlay_hint.enable(not current, { bufnr = ev.buf })
                        print("Inlay hints: " .. (not current and "Enabled" or "Disabled"))
                    end, { buffer = ev.buf, desc = "Toggle Inlay Hints" })
                end
            end,
        })

        -- Define sign icons for each severity
        local signs = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "󰠠 ",
            [vim.diagnostic.severity.INFO] = " ",
        }

        -- Set diagnostic config
        vim.diagnostic.config({
            signs = {
                text = signs,
            },
            virtual_text = true,
            underline = true,
            update_in_insert = false,
        })

        -- Setup servers
        local cmp_nvim_lsp = require("cmp_nvim_lsp")
        local capabilities = cmp_nvim_lsp.default_capabilities()

        -- Global LSP settings (applied to all servers)
        vim.lsp.config('*', {
            capabilities = capabilities,
        })

        -- Configure and enable LSP servers
        -- lua_ls
        vim.lsp.config("lua_ls", {
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { "vim" },
                    },
                    completion = {
                        callSnippet = "Replace",
                    },
                    workspace = {
                        library = {
                            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                            [vim.fn.stdpath("config") .. "/lua"] = true,
                        },
                    },
                },
            },
        })
        vim.lsp.enable("lua_ls")

        -- emmet_language_server
        vim.lsp.config("emmet_language_server", {
            filetypes = {
                "css",
                "eruby",
                "html",
                "javascript",
                "javascriptreact",
                "less",
                "sass",
                "scss",
                "pug",
                "typescriptreact",
            },
            init_options = {
                includeLanguages = {},
                excludeLanguages = {},
                extensionsPath = {},
                preferences = {},
                showAbbreviationSuggestions = true,
                showExpandedAbbreviation = "always",
                showSuggestionsAsSnippets = false,
                syntaxProfiles = {},
                variables = {},
            },
        })
        vim.lsp.enable("emmet_language_server")

        -- emmet_ls
        vim.lsp.config("emmet_ls", {
            filetypes = {
                "html",
                "typescriptreact",
                "javascriptreact",
                "css",
                "sass",
                "scss",
                "less",
                "svelte",
            },
        })
        vim.lsp.enable("emmet_ls")

        -- ts_ls (TypeScript/JavaScript)
        vim.lsp.config("ts_ls", {
            filetypes = {
                "javascript",
                "javascriptreact",
                "typescript",
                "typescriptreact",
            },
            single_file_support = true,
            init_options = {
                preferences = {
                    includeCompletionsForModuleExports = true,
                    includeCompletionsForImportStatements = true,
                },
            },
        })
        vim.lsp.enable("ts_ls")

        -- gopls
        vim.lsp.config("gopls", {
            settings = {
                gopls = {
                    analyses = {
                        unusedparams = true,
                    },
                    staticcheck = true,
                    gofumpt = true,
                },
            },
        })
        vim.lsp.enable("gopls")
        vim.lsp.enable("pyright")
        vim.lsp.config("qmlls", {
            cmd = { "qmlls", "-I", "/run/current-system/sw/lib/qt-6/qml" },
        })
        vim.lsp.enable("qmlls")
        vim.lsp.enable("rust-analyzer")

        -- 👇 New Configuration, Data, and Script File LSPs
        vim.lsp.enable("taplo")    -- TOML
        vim.lsp.enable("yamlls")   -- YAML
        vim.lsp.enable("jsonls")   -- JSON
        vim.lsp.enable("marksman") -- Markdown
        vim.lsp.enable("bashls")   -- Bash/Shell scripts

        -- Nix LSP (nil_ls or nixd)
        vim.lsp.config("nil_ls", {
            settings = {
                ["nil"] = {
                    formatting = { command = { "nixfmt" } },
                },
            },
        })
        if vim.fn.executable("nixd") == 1 then
            vim.lsp.enable("nixd")
        else
            vim.lsp.enable("nil_ls")
        end
    end,
}
