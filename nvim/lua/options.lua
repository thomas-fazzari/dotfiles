local o = vim.o

o.clipboard = "unnamedplus"
o.mouse = "a"
o.undofile = true
o.updatetime = 250
o.timeoutlen = 400

o.number = true
o.numberwidth = 2
o.ruler = false
o.signcolumn = "yes"
o.cursorline = true
o.cursorlineopt = "number"
o.laststatus = 3
o.showmode = false
o.splitbelow = true
o.splitright = true
o.splitkeep = "screen"
o.scrolloff = 6
o.wrap = true
o.linebreak = true
o.breakindent = true
o.winborder = "rounded"
vim.opt.fillchars = { eob = " " }
vim.opt.shortmess:append "sI"

o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true
o.ignorecase = true
o.smartcase = true
vim.opt.whichwrap:append "<>[]hl"

-- Tools come from mise, not from Neovim's language providers
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
