-- A colorscheme clears every highlight group, so redefine this one after each load
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#219fd5", fg = "#011627" })
  end,
})
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank { higroup = "YankHighlight", timeout = 250 }
  end,
})

-- nvim-treesitter (main branch) installs parsers but leaves highlighting to Neovim
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- Pick up edits the agent makes from another herdr tab. FocusGained alone is not enough:
-- the multiplexer may not forward focus events
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave" }, {
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd.checktime()
    end
  end,
})
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  callback = function(args)
    vim.notify("Reloaded " .. vim.fn.fnamemodify(args.file, ":."))
  end,
})

-- Autosave 2s after the last change, and when leaving the buffer.
-- vim.b.autosaving tells conform to skip formatting, so the text does not shift while typing
local autosave_delay_ms = 2000
local autosave_timers = {}

local function disk_mtime(buf)
  local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
  return stat and stat.mtime.sec .. "." .. stat.mtime.nsec
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "FileChangedShellPost" }, {
  callback = function(args)
    vim.b[args.buf].disk_mtime = disk_mtime(args.buf)
  end,
})

local function autosave(buf)
  if
    not vim.api.nvim_buf_is_valid(buf)
    or not vim.bo[buf].modified
    or vim.bo[buf].buftype ~= ""
    or vim.api.nvim_buf_get_name(buf) == ""
  then
    return
  end

  -- The agent changed the file since it was read: let checktime ask which version to keep
  -- instead of overwriting the agent's edit
  if vim.b[buf].disk_mtime and disk_mtime(buf) ~= vim.b[buf].disk_mtime then
    vim.schedule(function()
      vim.cmd.checktime(buf)
    end)
    return
  end

  vim.b[buf].autosaving = true
  vim.api.nvim_buf_call(buf, function()
    vim.cmd "silent! update"
  end)
  vim.b[buf].autosaving = false
end

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  callback = function(args)
    local timer = autosave_timers[args.buf]
    if timer then
      timer:stop()
    else
      timer = assert(vim.uv.new_timer())
      autosave_timers[args.buf] = timer
    end
    timer:start(
      autosave_delay_ms,
      0,
      vim.schedule_wrap(function()
        if vim.fn.mode() ~= "i" then
          autosave(args.buf)
        end
      end)
    )
  end,
})
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  callback = function(args)
    autosave(args.buf)
  end,
})
vim.api.nvim_create_autocmd("BufWipeout", {
  callback = function(args)
    local timer = autosave_timers[args.buf]
    if timer then
      timer:close()
      autosave_timers[args.buf] = nil
    end
  end,
})

-- .fs is also Forth for Neovim's detection, and MDX has no filetype of its own
vim.filetype.add {
  extension = { fs = "fsharp", fsi = "fsharp", mdx = "markdown" },
}
