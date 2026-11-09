vim.g.mapleader = " "
vim.g.maplocalleader = " "

require "options"
require "autocmds"

local trusted_root = vim.uv.fs_realpath(vim.fs.joinpath(vim.env.HOME, "Dev"))
local secure_read = vim.secure.read
vim.secure.read = function(path)
  local fullpath = vim.uv.fs_realpath(vim.fs.normalize(path))
  if not (trusted_root and fullpath and vim.fs.relpath(trusted_root, fullpath)) then
    return secure_read(path)
  end
  if vim.fn.isdirectory(fullpath) == 1 then
    return true
  end
  local file = assert(io.open(fullpath, "r"))
  local contents = file:read "*a"
  file:close()
  return contents
end

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  defaults = { lazy = true },
  install = { colorscheme = { "tokyonight" } },
  change_detection = { notify = false },
  rocks = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "netrwPlugin",
        "rplugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

require "mappings"
require "lsp"

if vim.env.REX_SESSION then
  require "agent"
end
