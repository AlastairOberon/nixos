local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- General settings group
local general_group = augroup("AlastairGeneral", { clear = true })

-- 1. Highlight on yank
autocmd("TextYankPost", {
    group = general_group,
    desc = "Highlight text when yanked",
    callback = function()
        vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
    end,
})

-- 2. Auto-create missing parent directories when saving a file
autocmd("BufWritePre", {
    group = general_group,
    desc = "Auto-create non-existent parent directories on save",
    callback = function(event)
        if event.match:match("^%w%w+:[\\/][\\/]") then
            return
        end
        local file = vim.uv.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    end,
})

-- 3. Restore cursor position when reopening a file
autocmd("BufReadPost", {
    group = general_group,
    desc = "Go to last cursor position when opening a file",
    callback = function(event)
        local exclude = { "gitcommit", "gitrebase" }
        local buf = event.buf
        if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_pos_restored then
            return
        end
        vim.b[buf].last_pos_restored = true
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local line_count = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= line_count then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- 4. Auto-resize splits when window is resized
autocmd("VimResized", {
    group = general_group,
    desc = "Auto-balance splits on window resize",
    callback = function()
        local current_tab = vim.fn.tabpagenr()
        vim.cmd("tabdo wincmd =")
        vim.cmd("tabnext " .. current_tab)
    end,
})

-- 5. Close utility buffers easily with <q>
autocmd("FileType", {
    group = general_group,
    desc = "Close utility buffers with q",
    pattern = {
        "help",
        "lspinfo",
        "man",
        "notify",
        "qf",
        "query",
        "checkhealth",
        "startuptime",
        "tsplayground",
        "PlenaryTestPopup",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true, desc = "Quit buffer" })
    end,
})

-- 6. Auto reload file when it changes on disk
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = general_group,
    desc = "Check if files need to be reloaded when focusing Neovim",
    callback = function()
        if vim.o.buftype ~= "nofile" then
            vim.cmd("checktime")
        end
    end,
})

-- 7. Terminal mode ergonomics
local term_group = augroup("AlastairTerminal", { clear = true })

autocmd("TermOpen", {
    group = term_group,
    desc = "Terminal mode settings",
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.scrolloff = 0
        vim.cmd("startinsert")
    end,
})
