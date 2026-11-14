return {
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
}
