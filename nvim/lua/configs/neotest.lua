local neotest = require "neotest"

neotest.setup {
  adapters = {
    require "neotest-vstest",
  },
}

local map = vim.keymap.set

map("n", "<F6>", function()
  neotest.run.run { strategy = "dap" }
end, { desc = "Neotest: debug nearest test" })

map("n", "<leader>dt", function()
  neotest.run.run { strategy = "dap" }
end, { desc = "Neotest: debug nearest test" })

map("n", "<leader>tt", function()
  neotest.run.run()
end, { desc = "Neotest: run nearest test" })

map("n", "<leader>tf", function()
  neotest.run.run(vim.fn.expand "%")
end, { desc = "Neotest: run file" })

map("n", "<leader>tl", function()
  neotest.run.run_last()
end, { desc = "Neotest: run last" })

map("n", "<leader>ts", function()
  neotest.summary.toggle()
end, { desc = "Neotest: summary" })

map("n", "<leader>to", function()
  neotest.output.open { enter = true, auto_close = true }
end, { desc = "Neotest: output" })

map("n", "<leader>tS", function()
  neotest.run.stop()
end, { desc = "Neotest: stop" })
