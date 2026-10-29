return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(buf)
        local gs = require "gitsigns"
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = "Git: " .. desc })
        end

        map("n", "]h", function()
          gs.nav_hunk "next"
        end, "next hunk")
        map("n", "[h", function()
          gs.nav_hunk "prev"
        end, "previous hunk")
        map("n", "<leader>gs", gs.stage_hunk, "stage/unstage hunk")
        map("n", "<leader>gr", gs.reset_hunk, "discard hunk")
        map("n", "<leader>gh", gs.preview_hunk_inline, "preview hunk")
        map("n", "<leader>gb", gs.blame_line, "blame line")
      end,
    },
  },

  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>Neogit kind=split<cr>", desc = "Git status" },
    },
    opts = {},
  },

  -- Side-by-side diffs of the working tree, staged changes and history, refreshed as files change.
  -- Hunk keys match the gitsigns ones above
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "Review changes" },
      { "<leader>gl", "<cmd>CodeDiff history<cr>", desc = "Review history" },
    },
    opts = {
      keymaps = {
        view = {
          stage_hunk = "<leader>gs",
          unstage_hunk = "<leader>gu",
          discard_hunk = "<leader>gr",
        },
      },
    },
  },

  -- Line references and review comments sent to the agent in this herdr workspace (<leader>a prefix)
  {
    "ChmaraX/herdr-nvim",
    event = "VeryLazy",
    cond = vim.env.HERDR_ENV == "1",
    opts = {},
  },
}
