require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

for _, dir in ipairs {
  "~/.dotnet/tools",
} do
  local path = vim.fn.expand(dir)
  if vim.fn.isdirectory(path) == 1 then
    vim.env.PATH = path .. ":" .. vim.env.PATH
  end
end
