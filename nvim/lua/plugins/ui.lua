-- Colorscheme spec comes from the active theme, switched with `mise run theme <name>`.
local theme = vim.fs.joinpath(vim.fs.dirname(vim.fn.resolve(vim.fn.stdpath "config")), "themes/current/nvim.lua")

return {
  vim.uv.fs_stat(theme) and dofile(theme) or {},

  {
    "nvim-mini/mini.nvim",
    lazy = false,
    config = function()
      local icons = require "mini.icons"
      icons.setup()
      -- fzf-lua and others ask for nvim-web-devicons
      icons.mock_nvim_web_devicons()

      local statusline = require "mini.statusline"
      statusline.setup {
        content = {
          active = function()
            -- A trunc_width wider than any window keeps the one-letter mode names
            local mode, mode_hl = statusline.section_mode { trunc_width = 1000 }
            return statusline.combine_groups {
              { hl = mode_hl, strings = { mode } },
              { hl = "MiniStatuslineDevinfo", strings = { statusline.section_git {} } },
              { hl = "MiniStatuslineFileinfo", strings = { statusline.section_diagnostics {} } },
              "%<",
              { hl = "MiniStatuslineFilename", strings = { "%f%m%r" } },
              "%=",
              { hl = "MiniStatuslineFileinfo", strings = { "%l:%v" } },
            }
          end,
        },
      }
      require("mini.ai").setup()
      require("mini.surround").setup()
      require("mini.pairs").setup()
      require("mini.bufremove").setup()

      -- Replaces vim.notify and shows LSP progress, such as Roslyn loading a solution
      require("mini.notify").setup()

      local jump2d = require "mini.jump2d"
      jump2d.setup { mappings = { start_jumping = "" } }
      vim.keymap.set({ "n", "x", "o" }, "<leader>j", function()
        jump2d.start(jump2d.builtin_opts.word_start)
      end, { desc = "Jump to a word" })
    end,
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>a", group = "agent" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "find/files" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "harpoon" },
        { "<leader>l", group = "lsp" },
        { "<leader>t", group = "test" },
      },
    },
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = { scope = { enabled = false } },
  },

  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    -- "faster smear" values
    opts = {
      stiffness = 0.8,
      trailing_stiffness = 0.6,
      stiffness_insert_mode = 0.7,
      trailing_stiffness_insert_mode = 0.7,
      damping = 0.95,
      damping_insert_mode = 0.95,
      distance_stop_animating = 0.5,
      -- Ghostty draws the legacy computing block symbols itself, so the trail needs no
      -- background color over the transparent background
      legacy_computing_symbols_support = true,
    },
  },

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    opts = { blend = { factor = 0.22 } },
  },
}
