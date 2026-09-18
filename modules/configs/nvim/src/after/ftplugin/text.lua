local set = vim.opt_local

-- Soft wrapping for reading and writing prose
set.wrap = true
set.linebreak = true

-- Spellcheck
set.spell = true
set.spelllang = "en_us"

-- Move by visual lines (ideal for wrapped paragraphs)
local opts = { buffer = true, silent = true }
vim.keymap.set("n", "j", "gj", opts)
vim.keymap.set("n", "k", "gk", opts)
vim.keymap.set("n", "<Down>", "gj", opts)
vim.keymap.set("n", "<Up>", "gk", opts)

-- Smart list auto-continuation on Enter and 'o'
set.formatoptions:append("r")
set.formatoptions:append("o")
set.comments = "b:*,b:-,b:+,n:>,b:1."

-- Quick formatting helpers
local function surround_selection(prefix, suffix)
    return function()
        local s_start = vim.fn.getpos("'<")
        local s_end = vim.fn.getpos("'>")
        local n_lines = math.abs(s_end[2] - s_start[2]) + 1
        local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
        if #lines == 0 then return end
        if n_lines == 1 then
            local line = lines[1]
            local col1 = s_start[3]
            local col2 = s_end[3]
            local new_line = line:sub(1, col1 - 1) .. prefix .. line:sub(col1, col2) .. suffix .. line:sub(col2 + 1)
            vim.api.nvim_buf_set_lines(0, s_start[2] - 1, s_end[2], false, { new_line })
        end
    end
end

-- Document statistics
local function show_document_stats()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local word_count = 0
    local char_count = 0
    for _, line in ipairs(lines) do
        char_count = char_count + #line
        for _ in line:gmatch("%S+") do
            word_count = word_count + 1
        end
    end
    local reading_time = math.ceil(word_count / 200) -- ~200 WPM
    print(string.format("Lines: %d | Words: %d | Chars: %d | Est. Reading: ~%d min", #lines, word_count, char_count, reading_time))
end

vim.keymap.set("n", "<leader>wW", show_document_stats, { buffer = true, desc = "Show Document Word Count & Reading Time" })
vim.keymap.set("v", "<leader>wb", surround_selection("**", "**"), { buffer = true, desc = "Bold selection (**)" })
vim.keymap.set("v", "<leader>wi", surround_selection("*", "*"), { buffer = true, desc = "Italic selection (*)" })
vim.keymap.set("v", "<leader>wq", surround_selection("> ", ""), { buffer = true, desc = "Blockquote selection (>)" })
