local dap = require "dap"
local dapui = require "dapui"

local adapter = {
  type = "executable",
  command = vim.fn.exepath "netcoredbg",
  args = { "--interpreter=vscode" },
}

dap.adapters.coreclr = adapter
dap.adapters.netcoredbg = adapter

local function pick_dll()
  return require("dap.utils").pick_file {
    filter = function(path)
      local lower = path:lower()
      return vim.endswith(lower, ".dll")
        and (lower:find("/bin/debug/", 1, true) or lower:find("/bin/release/", 1, true)) ~= nil
    end,
    executables = false,
  }
end

dap.configurations.cs = {
  {
    type = "coreclr",
    name = "Launch (select dll)",
    request = "launch",
    program = pick_dll,
    cwd = function()
      return vim.fn.getcwd()
    end,
  },
}

vim.fn.sign_define("DapBreakpoint", { text = "⚪", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapStopped", { text = "🔴", texthl = "DiagnosticError" })
vim.fn.sign_define("DapBreakpointRejected", { text = "⭕", texthl = "DiagnosticWarn" })

dapui.setup {
  expand_lines = true,
  controls = { enabled = false },
  floating = { border = "rounded" },
  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.5 },
        { id = "stacks", size = 0.5 },
      },
      size = 15,
      position = "bottom",
    },
  },
}

dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end

local map = vim.keymap.set

map("n", "<F5>", function()
  dap.continue()
end, { desc = "DAP: continue/start" })

map("n", "<F8>", function()
  dap.step_out()
end, { desc = "DAP: step out" })

map("n", "<F9>", function()
  dap.toggle_breakpoint()
end, { desc = "DAP: toggle breakpoint" })

map("n", "<F10>", function()
  dap.step_over()
end, { desc = "DAP: step over" })

map("n", "<F11>", function()
  dap.step_into()
end, { desc = "DAP: step into" })

map("n", "<leader>dr", function()
  dap.repl.open()
end, { desc = "DAP: REPL" })

map("n", "<leader>dl", function()
  dap.run_last()
end, { desc = "DAP: run last" })

map("n", "<leader>du", function()
  dapui.toggle()
end, { desc = "DAP: toggle UI" })

map({ "n", "v" }, "<leader>dw", function()
  dapui.eval(nil, { enter = true })
end, { desc = "DAP: add to watches" })

map({ "n", "v" }, "<leader>dk", function()
  dapui.eval()
end, { desc = "DAP: peek value" })
