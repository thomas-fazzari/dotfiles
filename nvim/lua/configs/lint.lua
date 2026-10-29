local lint = require "lint"

lint.linters_by_ft = {
  markdown = { "markdownlint-cli2" },
}

local markdownlint = lint.linters["markdownlint-cli2"]
-- Without --no-globs, every run also lints the files listed in the project's config globs
markdownlint.args = { "--no-globs", "-" }

-- Projects pin markdownlint-cli2 in node_modules, and their configs extend presets from it
-- (markdownlint/style/prettier.json). Stdin input uses the config of the working directory,
-- so run the project's binary from the project root
local function lint_buffer(buf)
  if not lint.linters_by_ft[vim.bo[buf].filetype] then
    return
  end

  local root = vim.fs.root(buf, { "node_modules", ".git" }) or vim.fn.getcwd()
  local local_bin = vim.fs.joinpath(root, "node_modules/.bin/markdownlint-cli2")
  local cmd = vim.fn.executable(local_bin) == 1 and local_bin or "markdownlint-cli2"
  if vim.fn.executable(cmd) == 0 then
    return
  end

  markdownlint.cmd = cmd
  lint.try_lint(nil, { cwd = root })
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("lint", { clear = true }),
  callback = function(args)
    lint_buffer(args.buf)
  end,
})

-- The plugin loads on the markdown FileType, after the first BufReadPost
lint_buffer(0)
