-- LSP keys are in lua/lsp.lua, git hunk keys in lua/plugins/git.lua, harpoon keys in lua/plugins/editor.lua
local map = vim.keymap.set

local function notify_result(result, success)
  vim.schedule(function()
    if result.code == 0 then
      vim.notify(success)
    else
      vim.notify(vim.trim(result.stderr ~= "" and result.stderr or result.stdout), vim.log.levels.ERROR)
    end
  end)
end

map("n", ";", ":", { desc = "Command mode" })
map("i", "jk", "<Esc>")
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<C-s>", "<cmd>write<cr>", { desc = "Save and format" })
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
-- <C-k> stays signature help (lua/lsp.lua), as in the previous config. <C-w>k moves up
map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<leader>x", function()
  require("mini.bufremove").delete()
end, { desc = "Close buffer" })
map("n", "<leader>c", "gcc", { remap = true, desc = "Toggle comment" })
map("x", "<leader>c", "gc", { remap = true, desc = "Toggle comment" })
map("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment" })
map("x", "<leader>/", "gc", { remap = true, desc = "Toggle comment" })
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_format = "never" }
end, { desc = "Format" })

-- Search: fff for files and text, fzf-lua for the rest
map("n", "<leader>ff", function()
  require("fff").find_files()
end, { desc = "Find files" })
map("n", "<leader>fg", function()
  require("fff").live_grep()
end, { desc = "Grep" })
-- Same as <leader>fg, the grep key of the previous NvChad config
map("n", "<leader>fw", function()
  require("fff").live_grep()
end, { desc = "Grep" })
map("n", "<leader>fc", function()
  require("fff").live_grep_under_cursor()
end, { desc = "Grep word under cursor" })
map("n", "<leader>f.", function()
  require("fff").resume()
end, { desc = "Resume last search" })
map("n", "<leader>fr", "<cmd>GrugFar<cr>", { desc = "Search and replace" })
map("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "Buffers" })
map("n", "<leader>fp", "<cmd>FzfLua commands<cr>", { desc = "Commands" })
map("n", "<leader>fh", "<cmd>FzfLua helptags<cr>", { desc = "Help" })
map("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "Keymaps" })

map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })
map("n", "<leader>fe", function()
  if vim.bo.filetype ~= "NvimTree" then
    vim.cmd "NvimTreeFocus"
    return
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "NvimTree" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  vim.cmd "NvimTreeClose"
end, { desc = "Toggle file tree focus" })
map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
map("n", "<leader>fn", function()
  local dir = vim.fn.expand "%:.:h"
  vim.ui.input({
    prompt = "New file: ",
    default = dir == "" and "" or dir .. "/",
    completion = "file",
  }, function(path)
    if path and path ~= "" then
      vim.fn.mkdir(vim.fs.dirname(path), "p")
      vim.cmd.edit(vim.fn.fnameescape(path))
    end
  end)
end, { desc = "New file" })
map("n", "<leader>fd", function()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if
    file == "" or vim.fn.confirm("Move " .. vim.fn.fnamemodify(file, ":.") .. " to the Trash?", "&Yes\n&No", 2) ~= 1
  then
    return
  end
  vim.system({ "trash", file }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify(vim.trim(result.stderr), vim.log.levels.ERROR)
        return
      end
      require("mini.bufremove").delete(buf, true)
    end)
  end)
end, { desc = "Delete file" })

map("n", "<leader>gc", "<cmd>FzfLua git_branches<cr>", { desc = "Checkout branch" })
map("n", "<leader>gn", function()
  vim.ui.input({ prompt = "New branch: " }, function(name)
    if name and name ~= "" then
      vim.system({ "git", "switch", "--create", name }, { text = true }, function(result)
        notify_result(result, "Switched to " .. name)
      end)
    end
  end)
end, { desc = "New branch" })
map("n", "<leader>gp", function()
  vim.system({ "git", "pull" }, { text = true }, function(result)
    notify_result(result, "Pulled")
    vim.schedule(vim.cmd.checktime)
  end)
end, { desc = "Pull" })
