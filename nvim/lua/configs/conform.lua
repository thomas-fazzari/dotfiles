local options = {
  formatters_by_ft = {
    bash = { "shfmt" },
    cs = { "csharpier" },
    css = { "oxfmt" },
    fish = { "fish_indent" },
    fsharp = { "fantomas" },
    go = { "goimports", "gofumpt" },
    html = { "oxfmt" },
    javascript = { "oxfmt" },
    javascriptreact = { "oxfmt" },
    json = { "oxfmt" },
    jsonc = { "oxfmt" },
    lua = { "stylua" },
    less = { "oxfmt" },
    markdown = { "oxfmt" },
    perl = { "perltidy" },
    python = { "ruff_organize_imports", "ruff_format" },
    rust = { "rustfmt" },
    scss = { "oxfmt" },
    sh = { "shfmt" },
    svelte = { "oxfmt" },
    toml = { "oxfmt" },
    typescript = { "oxfmt" },
    typescriptreact = { "oxfmt" },
    typst = { "typstyle" },
    xml = { "csharpier" },
    yaml = { "oxfmt" },
  },

  format_on_save = function(bufnr)
    if vim.b[bufnr].autosaving then
      return nil
    end
    return { timeout_ms = 2000, lsp_format = "never" }
  end,
}

return options
