return {
  "lambdalisue/suda.vim",
  -- Load the plugin only when these commands are called or a file requires it
  cmd = { "SudaRead", "SudaWrite" },
  init = function()
    -- Automatically switch to sudo mode if you don't have write permissions
    vim.g.suda_smart_edit = 1
  end,
}
