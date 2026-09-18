return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters = {
				["markdown-toc"] = {
					condition = function(_, ctx)
						for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
							if line:find("<!%-%- toc %-%->") then
								return true
							end
						end
					end,
				},
				["markdownlint-cli2"] = {
					condition = function(_, ctx)
						local diag = vim.tbl_filter(function(d)
							return d.source == "markdownlint"
						end, vim.diagnostic.get(ctx.buf))
						return #diag > 0
					end,
				},
			},
			formatters_by_ft = {
				javascript = { "biome-check" },
				typescript = { "biome-check" },
				javascriptreact = { "biome-check" },
				typescriptreact = { "biome-check" },
				css = { "biome-check" },
				html = { "biome-check" },
				svelte = { "prettier" },
				graphql = { "prettier" },
				liquid = { "prettier" },
				lua = { "stylua" },
				python = { "isort", "black" },
				markdown = { "prettier", "markdown-toc" },

				-- Data/Config formatters
				json = { "biome-check" },
				jsonc = { "biome-check" },
				yaml = { "prettier" },
				toml = { "taplo" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				nix = { "nixfmt", "alejandra", stop_after_first = true },
			},
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				return { timeout_ms = 1000, lsp_fallback = true }
			end,
		})

		-- Configure individual formatters
		conform.formatters.prettier = {
			args = {
				"--stdin-filepath",
				"$FILENAME",
				"--tab-width",
				"4",
				"--use-tabs",
				"false",
			},
		}
		conform.formatters.shfmt = {
			prepend_args = { "-i", "4" },
		}

		-- User command to toggle format-on-save
		vim.api.nvim_create_user_command("FormatToggle", function(args)
			if args.bang then
				vim.b.disable_autoformat = not vim.b.disable_autoformat
				print("Format-on-save (buffer): " .. (vim.b.disable_autoformat and "Disabled" or "Enabled"))
			else
				vim.g.disable_autoformat = not vim.g.disable_autoformat
				print("Format-on-save (global): " .. (vim.g.disable_autoformat and "Disabled" or "Enabled"))
			end
		end, {
			desc = "Toggle format-on-save (use ! for buffer-only)",
			bang = true,
		})

		vim.keymap.set("n", "<leader>uf", "<cmd>FormatToggle<CR>", { desc = "Toggle format-on-save" })
		vim.keymap.set("n", "<leader>uF", "<cmd>FormatToggle!<CR>", { desc = "Toggle buffer format-on-save" })

		vim.keymap.set({ "n", "v" }, "<leader>cf", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			})
		end, { desc = "Format buffer or selection" })
	end,
}
