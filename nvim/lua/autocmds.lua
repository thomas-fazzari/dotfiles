require "nvchad.autocmds"

pcall(dofile, vim.g.base46_cache .. "semantic_tokens")
vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#219fd5", fg = "#011627" })

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank { higroup = "YankHighlight", timeout = 250 }
  end,
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "*.fs", "*.fsx", "*.fsi" },
  callback = function()
    vim.bo.filetype = "fsharp"
  end,
})
