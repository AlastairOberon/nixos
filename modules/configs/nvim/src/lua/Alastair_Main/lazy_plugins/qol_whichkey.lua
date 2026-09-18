return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    spec = {
      { "<leader>f", group = "Find / Files" },
      { "<leader>p", group = "Pick / Project" },
      { "<leader>g", group = "Git" },
      { "<leader>c", group = "Code / LSP" },
      { "<leader>s", group = "Splits / Search" },
      { "<leader>t", group = "Todos / Tasks" },
      { "<leader>x", group = "Trouble / Diagnostics" },
      { "<leader>u", group = "UI Toggles" },
      { "<leader>w", group = "Write / Prose" },
      { "<leader>n", group = "Notes / Scratch" },
      { "<leader>q", group = "Session / Quit" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer local keymaps (Which-Key)",
    },
  },
}

