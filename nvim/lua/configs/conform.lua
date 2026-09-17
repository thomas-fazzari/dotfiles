local options = {
  formatters_by_ft = {
    cs = { "csharpier" },
    css = { "oxfmt" },
    fsharp = { "fantomas" },
    html = { "oxfmt" },
    javascript = { "oxfmt" },
    javascriptreact = { "oxfmt" },
    json = { "oxfmt" },
    jsonc = { "oxfmt" },
    lua = { "stylua" },
    markdown = { "oxfmt" },
    svelte = { "prettier" },
    toml = { "oxfmt" },
    typescript = { "oxfmt" },
    typescriptreact = { "oxfmt" },
    typst = { "typstyle" },
    xml = { "csharpier" },
    yaml = { "oxfmt" },
  },

  format_on_save = {
    timeout_ms = 2000,
    lsp_format = "never",
  },
}

return options
