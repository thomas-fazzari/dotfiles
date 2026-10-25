require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

vim.keymap.del("n", "<leader>h")
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_format = "never" }
end, { desc = "format file" })
map("n", "<leader>fe", function()
  if vim.bo.filetype ~= "NvimTree" then
    vim.cmd "NvimTreeFocus"
    return
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "NvimTree" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  vim.cmd "NvimTreeClose"
end, { desc = "nvimtree toggle focus" })
map("n", "gr", "<cmd>Telescope lsp_references<CR>", { desc = "LSP references" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "LSP implementation" })
map("n", "gt", vim.lsp.buf.type_definition, { desc = "LSP type definition" })
map("n", "K", vim.lsp.buf.hover, { desc = "LSP hover" })
map("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "LSP signature help" })
map("n", "<F12>", vim.lsp.buf.definition, { desc = "LSP definition" })

map("n", "<leader>q", vim.lsp.buf.code_action, { desc = "LSP code action" })
map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP rename" })
map("n", "<leader>le", vim.diagnostic.open_float, { desc = "LSP diagnostic float" })
map("n", "<leader>ld", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })
map("n", "<leader>ff", function()
  require("fff").find_files()
end, { desc = "FFF: find files" })
map("n", "<leader>fw", function()
  require("fff").live_grep()
end, { desc = "FFF: live grep" })
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
