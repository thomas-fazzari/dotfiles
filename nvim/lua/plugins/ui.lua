return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local git = { modified = "#6183BB", added = "#449DAB", deleted = "#914C54", conflict = "#FFC777" }
      local oil_git = {
        Modified = git.modified,
        TypeChanged = git.modified,
        Added = git.added,
        Copied = git.added,
        Renamed = git.added,
        Untracked = git.added,
        Deleted = git.deleted,
        Unmerged = git.conflict,
      }

      require("tokyonight").setup {
        style = "moon",
        transparent = true,
        styles = { sidebars = "transparent", floats = "transparent" },
        on_highlights = function(hl, c)
          hl.CursorLineNr = { fg = c.fg, bold = true }
          for status, color in pairs(oil_git) do
            hl["OilGitStatusIndex" .. status] = { fg = color }
            hl["OilGitStatusWorkingTree" .. status] = { fg = color }
          end

          hl.LspInlayHint = { fg = c.dark3, italic = true }

          -- Transparent statusline in the colors of the starship prompt
          hl.StatusLine = { fg = c.fg_dark }
          hl.StatusLineNC = { fg = c.dark3 }
          hl.MiniStatuslineModeNormal = { fg = c.blue, bold = true }
          hl.MiniStatuslineModeInsert = { fg = c.green1, bold = true }
          hl.MiniStatuslineModeVisual = { fg = c.magenta, bold = true }
          hl.MiniStatuslineModeReplace = { fg = c.red1, bold = true }
          hl.MiniStatuslineModeCommand = { fg = c.cyan, bold = true }
          hl.MiniStatuslineModeOther = { fg = c.fg_dark, bold = true }
          hl.MiniStatuslineDevinfo = { fg = c.green1 }
          hl.MiniStatuslineFilename = { fg = c.blue }
          hl.MiniStatuslineFileinfo = { fg = c.dark5 }
          hl.MiniStatuslineInactive = { fg = c.dark3 }
        end,
      }
      vim.cmd.colorscheme "tokyonight"
    end,
  },

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
