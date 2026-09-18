local opts = { noremap = true, silent = true }

-- Leader key is set in options.lua, reaffirmed here
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Clear search highlights
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<C-c>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

-- Toggle Word Wrap
vim.keymap.set("n", "<leader>uw", "<cmd>set wrap!<CR>", { desc = "Toggle Word Wrap" })
vim.keymap.set("n", "<leader>w", "<cmd>set wrap!<CR>", { desc = "Toggle Word Wrap" })

-- Shifting selection (Up = K, Down = J, Left = <, Right = >)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move lines down in visual selection" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move lines up in visual selection" })
vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

-- Keep cursor centered during scrolling and search
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search match and center" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search match and center" })

-- Window navigation (<C-h/j/k/l>)
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Window resize with arrows
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Buffer navigation
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "[b", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })

-- Paste without replacing clipboard content
vim.keymap.set("x", "<leader>p", [["_dp]], { desc = "Paste without replacing register" })
vim.keymap.set("v", "p", '"_dp', opts)
-- Deleting without copying to clipboard content
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without copying" })

-- Prevents deleted single characters with 'x' from copying to clipboard
vim.keymap.set("n", "x", '"_x', opts)

-- Disables Q
vim.keymap.set("n", "Q", "<nop>")

-- Format buffer (routes to conform.nvim)
vim.keymap.set({ "n", "v" }, "<leader>f", function()
    local ok, conform = pcall(require, "conform")
    if ok then
        conform.format({ lsp_fallback = true, async = false, timeout_ms = 1000 })
    else
        vim.lsp.buf.format()
    end
end, { desc = "Format buffer or selection" })

-- Search and replace under cursor globally
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor globally" })

-- Make File executable (fixed !chmod)
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { desc = "Make File Executable" })

-- Window Splits (<leader>s...)
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split Window Vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split Window Horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Equalize Splits" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close Split" })

-- Copy Filepath to Clipboard
vim.keymap.set("n", "<leader>fp", function()
    local filepath = vim.fn.expand("%:~")
    vim.fn.setreg("+", filepath)
    print("Filepath Copied to Clipboard: " .. filepath)
end, { desc = "Copy File path to clipboard" })

-- Terminal mode escape
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

