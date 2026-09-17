require("nvchad.configs.lspconfig").defaults()

local servers = {
  "html",
  "cssls",
  "roslyn_ls",
  "fsautocomplete",
  "tinymist",
  "tsc",
  "markdown_oxide",
}
vim.lsp.config("roslyn_ls", {
  filetypes = { "cs", "razor" },
  settings = {
    ["csharp|background_analysis"] = {
      dotnet_analyzer_diagnostics_scope = "openFiles",
      dotnet_compiler_diagnostics_scope = "openFiles",
    },
  },
})

vim.lsp.config("tsc", {
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json" },
})

vim.lsp.enable(servers)

vim.diagnostic.config {
  underline = false,
  virtual_text = false,
  update_in_insert = false,
  severity_sort = true,
}

-- read :h vim.lsp.config for changing options of lsp servers
