return {
	"williamboman/mason.nvim",
	lazy = false,
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"neovim/nvim-lspconfig",
		-- "saghen/blink.cmp",
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			PATH = "prepend",
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			automatic_enable = false,
			ensure_installed = {
				-- Language Servers
				"lua_ls",
				"ts_ls",
				"html",
				"cssls",
				"tailwindcss",
				"gopls",
				"angularls",
				"emmet_ls",
				"emmet_language_server",
				"marksman",
				"pyright",
				"clangd",
				"denols",
				"taplo",
				"yamlls",
				"jsonls",
				"bashls",
			},
		})

		mason_tool_installer.setup({
			run_on_start = true,
			start_delay = 500,
			debounce_hours = 5,
			ensure_installed = {
				-- Formatters
				"prettier",
				"stylua",
				"isort",
				"black",
				"shfmt",
				"biome",

				-- Linters
				"pylint",
				"shellcheck",
				"yamllint",
				"markdownlint",
				"markdownlint-cli2",
				"hadolint",
				"eslint_d",
			},
		})
	end,
}
