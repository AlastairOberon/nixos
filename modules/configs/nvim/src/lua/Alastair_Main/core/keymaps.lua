local opts = { noremap = true, silent = true }

--LEader Key to Trigger Cutoms Keybinds
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Toggle Word Wrap
vim.keymap.set('n', '<leader>w', ':set wrap!<CR>', { desc = 'Toggle Word Wrap' })

--Shifting selection (Up = K, Down = J, Left = <, Right = >)
vim.keymap.set ("v", "J", ":m '>+1<CR>gv=gv", {desc = "Moves lines down in visual selection" })
vim.keymap.set ("v", "K", ":m '<-2<CR>gv=gv", {desc = "Moves lines up in visual selection" })
vim.keymap.set ("v", "<", "<gv", opts)
vim.keymap.set ("v", ">", ">gv", opts)

--Paste without replacing clipboard content
vim.keymap.set ("x", "<leader>p", [["_dp]])
--Paste without replacing clipboard content in Visual mode
vim.keymap.set ("v", "p", '"_dp', opts)
--Deleting without copying to clipboard content
vim.keymap.set ({"n", "v"}, "<leader>d", [["_d]])

--Exit Insert Mode
vim.keymap.set ("i", "<C=c>", "<Esc>")
--Clear Search Highlights
vim.keymap.set ("n", "<C=c>", ":nohl<CR>", { desc = "Clear search hl", silent = true})

--LSP Formatting
vim.keymap.set ("n", "<leader>f", vim.lsp.buf.format)
--Disables Q
vim.keymap.set ("n", "Q", "<nop>")
--Prevents deleted characters from being copied to the clipboard
vim.keymap.set ("n", "x", '"_x', opts)


--Search and replace, global
vim.keymap.set ("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {desc= "Replace the word the cursor is on globally" })
--Make File executable
vim.keymap.set ("n", "<leader>x", "<cmd>@chmod +x %<CR>", {desc= "Makes File Executable" })

--Split
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split Window Vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>h", { desc = "Split Window Horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Equalize Splits" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "CLose Split" })

--Copy Filepath to Clipboard
vim.keymap.set("n", "<leader>fp", function()
    local filepath = vim.fn.expand("%:~")
    vim.fn.setreg("+", filepath)
    print("Filepath Copied to Clipboard: ".. filepath)
end, { desc = "Copy File path to clipboard"})
