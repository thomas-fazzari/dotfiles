return {
  "Mofiqul/vscode.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    local git = { modified = "#0078D4", added = "#2EA043", deleted = "#F85149", conflict = "#E4676B" }
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
    local c = {
      fg = "#CCCCCC",
      muted = "#8B949E",
      nr = "#444444",
      comment = "#888888",
      docstring = "#AAAAAA",
      blue = "#569CD6",
      light_blue = "#9CDCFE",
      teal = "#4EC9B0",
      pink = "#C586C0",
      yellow = "#DCDCAA",
      green = "#B5CEA8",
      red = "#F44747",
    }

    local overrides = {
      Comment = { fg = c.comment, italic = true },
      SpecialComment = { fg = c.docstring, italic = true },
      ["@comment"] = { link = "Comment" },
      ["@comment.documentation"] = { link = "SpecialComment" },
      ["@string.documentation"] = { link = "SpecialComment" },

      LineNr = { fg = c.nr },
      CursorLineNr = { fg = c.fg, bold = true },
      NormalFloat = { fg = c.fg },
      FloatBorder = { fg = c.nr },
      WinSeparator = { fg = "#262626" },
      LspInlayHint = { fg = c.muted, italic = true },

      GitSignsAdd = { fg = git.added },
      GitSignsChange = { fg = git.modified },
      GitSignsDelete = { fg = git.deleted },

      StatusLine = { fg = c.muted },
      StatusLineNC = { fg = c.nr },
      MiniStatuslineModeNormal = { fg = c.blue, bold = true },
      MiniStatuslineModeInsert = { fg = c.green, bold = true },
      MiniStatuslineModeVisual = { fg = c.pink, bold = true },
      MiniStatuslineModeReplace = { fg = c.red, bold = true },
      MiniStatuslineModeCommand = { fg = c.yellow, bold = true },
      MiniStatuslineModeOther = { fg = c.teal, bold = true },
      MiniStatuslineDevinfo = { fg = c.green },
      MiniStatuslineFilename = { fg = c.light_blue },
      MiniStatuslineFileinfo = { fg = c.muted },
      MiniStatuslineInactive = { fg = c.nr },
    }
    for status, color in pairs(oil_git) do
      overrides["OilGitStatusIndex" .. status] = { fg = color }
      overrides["OilGitStatusWorkingTree" .. status] = { fg = color }
    end

    require("vscode").setup {
      style = "dark",
      transparent = true,
      italic_inlayhints = true,
      color_overrides = { vscFront = c.fg },
      terminal_colors = false,
      group_overrides = overrides,
    }
    vim.cmd.colorscheme "vscode"

    local terminal = {
      "#313131",
      "#F44747",
      "#81B88B",
      "#D7BA7D",
      "#569CD6",
      "#C586C0",
      "#4EC9B0",
      "#AAAAAA",
      "#808080",
      "#F77E7E",
      "#B5CEA8",
      "#DCDCAA",
      "#9CDCFE",
      "#D6AAD3",
      "#83D9C8",
      "#CCCCCC",
    }
    for i, color in ipairs(terminal) do
      vim.g["terminal_color_" .. (i - 1)] = color
    end
  end,
}
