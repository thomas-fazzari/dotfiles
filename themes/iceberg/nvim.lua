return {
  "cocopon/iceberg.vim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.o.background = "dark"
    vim.cmd.colorscheme "iceberg"

    local c = {
      fg = "#C6C8D1",
      comment = "#6B7089",
      dim = "#444B71",
      blue = "#84A0C6",
      purple = "#A093C7",
      cyan = "#89B8C2",
      green = "#B4BE82",
      orange = "#E2A478",
      red = "#E27878",
    }
    local hl = {
      Normal = { fg = c.fg },
      NormalNC = { fg = c.fg },
      NormalFloat = { fg = c.fg },
      FloatBorder = { fg = c.dim },
      SignColumn = {},
      FoldColumn = { fg = c.dim },
      LineNr = { fg = c.dim },
      EndOfBuffer = {},
      CursorLineNr = { fg = c.orange, bold = true },
      LspInlayHint = { fg = c.dim, italic = true },

      StatusLine = { fg = c.fg },
      StatusLineNC = { fg = c.dim },
      MiniStatuslineModeNormal = { fg = c.orange, bold = true },
      MiniStatuslineModeInsert = { fg = c.green, bold = true },
      MiniStatuslineModeVisual = { fg = c.purple, bold = true },
      MiniStatuslineModeReplace = { fg = c.red, bold = true },
      MiniStatuslineModeCommand = { fg = c.cyan, bold = true },
      MiniStatuslineModeOther = { fg = c.fg, bold = true },
      MiniStatuslineDevinfo = { fg = c.green },
      MiniStatuslineFilename = { fg = c.blue },
      MiniStatuslineFileinfo = { fg = c.comment },
      MiniStatuslineInactive = { fg = c.dim },
    }
    local oil_git = {
      Modified = c.blue,
      TypeChanged = c.blue,
      Added = c.green,
      Copied = c.green,
      Renamed = c.green,
      Untracked = c.green,
      Deleted = c.red,
      Unmerged = c.orange,
    }
    for status, color in pairs(oil_git) do
      hl["OilGitStatusIndex" .. status] = { fg = color }
      hl["OilGitStatusWorkingTree" .. status] = { fg = color }
    end
    for group, spec in pairs(hl) do
      vim.api.nvim_set_hl(0, group, spec)
    end
  end,
}
