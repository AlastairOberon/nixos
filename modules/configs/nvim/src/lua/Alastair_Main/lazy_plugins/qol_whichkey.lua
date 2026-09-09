return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    -- This ensures your leader key triggers the timeout
    vim.o.timeout = true
    -- How many milliseconds to wait before popping up the menu (adjust to your liking)
    vim.o.timeoutlen = 300 
  end,
  opts = {
    -- You can leave this empty, the default settings are excellent
  },
  keys = {
    -- This adds your specific request: hitting <leader>? shows all keymaps
    {
      "<leader>",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Show local keymaps (Which-Key)",
    },
  },
}
