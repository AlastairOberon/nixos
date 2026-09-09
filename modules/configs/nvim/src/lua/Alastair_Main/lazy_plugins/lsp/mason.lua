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
				-- Your existing LSPs
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
				"clangd", -- Moved here from tool_installer
				"denols", -- Moved here from tool_installer

				-- New Data/Config LSPs
				"taplo", -- TOML
				"yamlls", -- YAML
				"jsonls", -- JSON
				"bashls", -- Bash scripts
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				-- Your existing Formatters & Linters
				"prettier",
				"stylua",
				"isort",
				"pylint",
				-- { 'eslint_d', version = '13.1.2' },

				-- New Linters
				"biome",
				"yamllint",
				"markdownlint",
				"hadolint",
			},
		})
	end,
}
