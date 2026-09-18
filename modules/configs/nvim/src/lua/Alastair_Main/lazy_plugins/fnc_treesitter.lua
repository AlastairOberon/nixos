return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        event = { "BufReadPre", "BufNewFile" },
        build = ":TSUpdate",
        config = function()
            local configs = require("nvim-treesitter.configs")

            configs.setup({
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = true },
                ensure_installed = {
                    "json", "javascript", "typescript", "tsx", "go", "yaml",
                    "html", "css", "python", "http", "prisma", "markdown",
                    "markdown_inline", "svelte", "graphql", "bash", "lua",
                    "vim", "dockerfile", "gitignore", "query", "vimdoc",
                    "c", "java", "rust", "ron", "nix", "toml", "diff", "regex",
                },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<C-space>",
                        node_incremental = "<C-space>",
                        scope_incremental = false,
                        node_decremental = "<bs>",
                    },
                },
            })
        end,
    },
    {
        "windwp/nvim-ts-autotag",
        opts = {}, -- Simplified setup for autotag
    },
}
