local noise_patterns = {
  "^%.git$",
  "^%.DS_Store$",
  "%.lockb?$",
  "%-lock%.json$",
  "%-lock%.ya?ml$",
  "^packages%.lock%.json$",
  "^go%.sum$",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- Installs whatever is missing in the background. Highlighting starts in autocmds.lua
      require("nvim-treesitter").install {
        "bash",
        "c_sharp",
        "css",
        "diff",
        "dockerfile",
        "fish",
        "fsharp",
        "git_config",
        "git_rebase",
        "gitcommit",
        "gitignore",
        "go",
        "gomod",
        "gosum",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "kdl",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "perl",
        "python",
        "query",
        "razor",
        "regex",
        "rust",
        "scss",
        "sql",
        "svelte",
        "toml",
        "tsx",
        "typescript",
        "typst",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      }
      vim.treesitter.language.register("bash", "conf")
    end,
  },

  -- Files and grep. fzf-lua covers the pickers fff does not have (LSP, git, help, commands)
  {
    "dmtrKovalenko/fff",
    lazy = false,
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    opts = {},
  },
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    opts = { fzf_colors = true },
    -- Loads fzf-lua on the first vim.ui.select
    init = function()
      vim.ui.select = function(...)
        require("fzf-lua").register_ui_select()
        return vim.ui.select(...)
      end
    end,
  },
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
  },

  {
    "stevearc/oil.nvim",
    -- Oil opens directory buffers in place of netrw, so it has to load at startup
    lazy = false,
    opts = {
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      keymaps = { q = { "actions.close", mode = "n" } },
      -- Picks up files that agents and other processes create or delete
      watch_for_changes = true,
      -- Dotfiles stay visible; only the noise is hidden
      view_options = {
        is_hidden_file = function(name)
          for _, pattern in ipairs(noise_patterns) do
            if name:find(pattern) then
              return true
            end
          end
          return false
        end,
      },
      win_options = { signcolumn = "yes:2" },
    },
  },
  {
    "refractalize/oil-git-status.nvim",
    dependencies = { "stevearc/oil.nvim" },
    lazy = false,
    opts = { show_ignored = false },
  },

  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- harpoon2's setup is a method, which lazy.nvim's opts would call without self
    config = function()
      require("harpoon"):setup()
    end,
    keys = function()
      local function list()
        return require("harpoon"):list()
      end
      local function menu()
        require("harpoon").ui:toggle_quick_menu(list())
      end
      local keys = {
        {
          "<leader>ha",
          function()
            list():add()
          end,
          desc = "Harpoon add file",
        },
        { "<leader>hh", menu, desc = "Harpoon menu" },
        {
          "<leader>hp",
          function()
            list():prev()
          end,
          desc = "Harpoon previous file",
        },
      }
      for i = 1, 5 do
        table.insert(keys, {
          "<leader>h" .. i,
          function()
            list():select(i)
          end,
          desc = "Harpoon file " .. i,
        })
      end
      return keys
    end,
  },

  { "rmagatti/goto-preview", opts = {} },

  {
    "HakonHarnes/img-clip.nvim",
    cmd = "PasteImage",
    opts = {
      default = {
        dir_path = "assets",
        relative_to_current_file = true,
        prompt_for_file_name = true,
        use_absolute_path = false,
      },
    },
    keys = {
      { "<leader>ip", "<cmd>PasteImage<cr>", desc = "Paste clipboard image" },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    opts = {
      enabled = false,
      latex = { enabled = false },
    },
    keys = {
      {
        "<D-V>",
        function()
          require("render-markdown").buf_toggle()
        end,
        ft = "markdown",
        desc = "Toggle Markdown preview",
      },
    },
  },
}
