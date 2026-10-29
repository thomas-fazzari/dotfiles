return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local git = { modified = "#6183BB", added = "#449DAB", deleted = "#914C54", conflict = "#BB7A61" }
      local tree_git = {
        Dirty = git.modified,
        Staged = git.added,
        New = git.added,
        Renamed = git.added,
        Deleted = git.deleted,
        Merge = git.conflict,
      }

      require("tokyonight").setup {
        style = "night",
        transparent = true,
        styles = { sidebars = "transparent", floats = "transparent" },
        on_highlights = function(hl, c)
          hl.CursorLineNr = { fg = c.fg, bold = true }
          hl.NvimTreeFolderIcon = { fg = c.dark5 }
          hl.NvimTreeFolderName = { fg = c.fg_sidebar }
          hl.NvimTreeOpenedFolderName = { fg = c.fg_sidebar }
          hl.NvimTreeEmptyFolderName = { fg = c.fg_sidebar }
          for status, color in pairs(tree_git) do
            hl["NvimTreeGit" .. status .. "Icon"] = { fg = color }
            hl["NvimTreeGitFile" .. status .. "HL"] = { fg = color }
            hl["NvimTreeGitFolder" .. status .. "HL"] = { fg = color }
          end

          hl.LspInlayHint = { fg = c.dark3, italic = true }

          -- Transparent statusline in the colors of the starship prompt
          hl.StatusLine = { fg = c.fg_dark }
          hl.StatusLineNC = { fg = c.dark3 }
          hl.MiniStatuslineModeNormal = { fg = "#7AA2F7", bold = true }
          hl.MiniStatuslineModeInsert = { fg = "#73DACA", bold = true }
          hl.MiniStatuslineModeVisual = { fg = "#BB9AF7", bold = true }
          hl.MiniStatuslineModeReplace = { fg = "#DB4B4B", bold = true }
          hl.MiniStatuslineModeCommand = { fg = "#7DCFFF", bold = true }
          hl.MiniStatuslineModeOther = { fg = c.fg_dark, bold = true }
          hl.MiniStatuslineDevinfo = { fg = "#73DACA" }
          hl.MiniStatuslineFilename = { fg = "#7AA2F7" }
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
      -- nvim-tree and others ask for nvim-web-devicons
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

      -- <leader>j, then the label of the target word
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
