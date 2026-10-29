-- Server settings live in lsp/<name>.lua and merge over nvim-lspconfig's defaults.
-- C# (roslyn.nvim) and Rust (rustaceanvim) start their own servers
vim.lsp.enable {
  "basedpyright",
  "bashls",
  "cssls",
  "fish_lsp",
  "fsautocomplete",
  "gopls",
  "html",
  "jsonls",
  "lua_ls",
  "markdown_oxide",
  "oxlint",
  "perlnavigator",
  "ruff",
  "tinymist",
  "tombi",
  "tsc",
  "yamlls",
}

vim.diagnostic.config {
  underline = false,
  virtual_text = false, -- tiny-inline-diagnostic renders them
  update_in_insert = false,
  severity_sort = true,
}

-- Neovim's default gr* LSP maps would delay the single-key gr below
for _, mode in ipairs { "n", "x" } do
  for _, lhs in ipairs { "grn", "gra", "grr", "gri", "grt", "grx" } do
    if vim.fn.maparg(lhs, mode) ~= "" then
      vim.keymap.del(mode, lhs)
    end
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = "LSP: " .. desc })
    end

    map("n", "gd", vim.lsp.buf.definition, "definition")
    map("n", "<F12>", vim.lsp.buf.definition, "definition")
    map("n", "gD", vim.lsp.buf.declaration, "declaration")
    -- Some servers have no references
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method "textDocument/references" then
      map("n", "gr", "<cmd>FzfLua lsp_references<cr>", "references")
    end
    map("n", "gi", vim.lsp.buf.implementation, "implementation")
    map("n", "gt", vim.lsp.buf.type_definition, "type definition")
    map("n", "gpd", function()
      require("goto-preview").goto_preview_definition()
    end, "peek definition")
    map("n", "gpi", function()
      require("goto-preview").goto_preview_implementation()
    end, "peek implementation")
    map("n", "gpt", function()
      require("goto-preview").goto_preview_type_definition()
    end, "peek type definition")
    map("n", "K", vim.lsp.buf.hover, "hover")
    map("n", "<C-k>", vim.lsp.buf.signature_help, "signature help")
    map("n", "<F2>", vim.lsp.buf.rename, "rename")
    map("n", "<leader>lr", vim.lsp.buf.rename, "rename")
    map({ "n", "x" }, "<leader>q", vim.lsp.buf.code_action, "code action")
    map("n", "<leader>le", vim.diagnostic.open_float, "line diagnostics")
    map("n", "<leader>ld", "<cmd>FzfLua diagnostics_document<cr>", "file diagnostics")
    map("n", "<leader>lD", "<cmd>FzfLua diagnostics_workspace<cr>", "workspace diagnostics")
    map("n", "<leader>ls", "<cmd>FzfLua lsp_document_symbols<cr>", "file symbols")
    map("n", "<leader>lS", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", "workspace symbols")

    if client:supports_method "textDocument/inlayHint" then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
      map("n", "<leader>lh", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = 0 }, { bufnr = 0 })
      end, "toggle inlay hints")
    end
  end,
})
