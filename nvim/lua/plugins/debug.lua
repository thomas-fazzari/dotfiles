return {
  {
    "mfussenegger/nvim-dap",
    ft = { "cs", "fsharp" },
    keys = { "<F5>", "<F9>" },
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      require "configs.dap"
    end,
  },

  {
    "nvim-neotest/neotest",
    ft = { "cs", "fsharp" },
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nsidorenco/neotest-vstest",
    },
    config = function()
      require "configs.neotest"
    end,
  },
}
