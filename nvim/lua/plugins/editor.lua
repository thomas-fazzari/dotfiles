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
        "json",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "perl",
        "python",
        "razor",
        "regex",
        "rust",
        "sql",
        "svelte",
        "toml",
        "tsx",
        "typescript",
        "typst",
        "vim",
        "vimdoc",
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
      view_options = { show_hidden = true },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeClose" },
    opts = {
      hijack_netrw = false,
      hijack_directories = { enable = false },
      hijack_cursor = true,
      sync_root_with_cwd = true,
      update_focused_file = { enable = true },
      view = { width = 30, preserve_window_proportions = true },
      -- Git status as colored names and a letter on the right
      renderer = {
        root_folder_label = false,
        highlight_git = "name",
        indent_markers = { enable = true },
        icons = {
          git_placement = "right_align",
          glyphs = {
            git = {
              unstaged = "M",
              staged = "M",
              unmerged = "!",
              renamed = "R",
              untracked = "U",
              deleted = "D",
              ignored = "",
            },
          },
        },
      },
    },
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
        -- Same menu as <leader>hh, which is editable
        { "<leader>he", menu, desc = "Harpoon edit files" },
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
    "brianhuster/live-preview.nvim",
    ft = "markdown",
    config = function()
      require("livepreview.config").set {}
    end,
  },
}
