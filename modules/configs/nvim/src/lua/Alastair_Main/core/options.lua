-- Leader key (set before any plugins load)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.cmd("let g:netrw_banner = 0")

-- Line numbers
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

-- Tabs & Indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.linebreak = true -- Prevents breaking words in the middle

-- Backup & Undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- Search settings
vim.opt.incsearch = true
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

-- Visuals & Window settings
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.backspace = { "start", "eol", "indent" }
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.fillchars = { eob = " " } -- cleaner look without tildes at end of buffer
vim.opt.smoothscroll = true -- Smooth scrolling for wrapped lines and mouse

-- Behavior & Clipboard
vim.opt.clipboard:append("unnamedplus")
vim.opt.mouse = "a"
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"
vim.opt.isfname:append("@-@")
vim.g.editorconfig = true

-- Session options for persistence
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
