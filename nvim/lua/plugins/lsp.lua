return {
  -- Server configs (lsp/*.lua) for vim.lsp.enable in lua/lsp.lua
  { "neovim/nvim-lspconfig", lazy = false },
  { "b0o/SchemaStore.nvim" },

  -- Loaded at startup so its plugin file adds completion capabilities before any server starts
  {
    "saghen/blink.cmp",
    version = "1.*",
    lazy = false,
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
          require "configs.luasnip"
        end,
      },
    },
    opts = {
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      snippets = { preset = "luasnip" },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      completion = { documentation = { auto_show = true } },
      signature = { enabled = true },
    },
  },

  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    opts = {},
    init = function()
      local function base_dir_exists(watcher)
        local base = type(watcher.globPattern) == "table" and watcher.globPattern.baseUri
        if not base then
          return true
        end
        local uri = type(base) == "table" and base.uri or base
        return vim.uv.fs_stat(vim.uri_to_fname(uri)) ~= nil
      end

      -- The server also asks to watch dotnet's default install dir (/usr/local/share/dotnet/packs),
      -- which does not exist with mise's dotnet, and Neovim reports ENOENT for it on every start.
      -- An explicit vim.lsp.config call takes precedence over roslyn.nvim's handler. It runs in init
      -- because the plugin's own plugin/ file starts the client as soon as it loads
      vim.lsp.config("roslyn", {
        handlers = {
          ["client/registerCapability"] = function(err, result, ctx)
            for _, registration in ipairs(result.registrations) do
              if registration.method == "workspace/didChangeWatchedFiles" then
                local options = registration.registerOptions
                options.watchers = vim.tbl_filter(base_dir_exists, options.watchers)
              end
            end
            return vim.lsp.handlers["client/registerCapability"](err, result, ctx)
          end,
        },
      })
    end,
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^9",
    -- rustaceanvim lazy-loads itself on Rust buffers
    lazy = false,
    init = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              cargo = { buildScripts = { enable = true } },
              -- Clippy through mbx's Cargo shim
              check = {
                overrideCommand = {
                  vim.fs.joinpath(vim.env.HOME, "Library/Application Support/mbx/bin/cargo"),
                  "clippy",
                  "--workspace",
                  "--all-targets",
                  "--target-dir",
                  "target/rust-analyzer",
                  "--message-format=json",
                },
              },
              procMacro = { enable = true },
              imports = { granularity = { group = "module" } },
              inlayHints = {
                closureReturnTypeHints = { enable = "with_block" },
                lifetimeElisionHints = { enable = "skip_trivial" },
              },
            },
          },
        },
      }
    end,
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = require "configs.conform",
  },
  {
    "mfussenegger/nvim-lint",
    ft = { "markdown" },
    config = function()
      require "configs.lint"
    end,
  },
}
