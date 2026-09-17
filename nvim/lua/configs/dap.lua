local dap = require "dap"
local dapui = require "dapui"

local command = vim.fn.exepath "netcoredbg"
if command == "" then
  command = vim.fn.expand "~/.local/share/netcoredbg/netcoredbg"
end

local adapter = {
  type = "executable",
  command = command,
  args = { "--interpreter=vscode" },
}

dap.adapters.coreclr = adapter
dap.adapters.netcoredbg = adapter

local function pick_dll()
  local dlls = vim.fs.find(function(name)
    return name:match "%.dll$" ~= nil
  end, { path = vim.fn.getcwd(), type = "file", limit = math.huge })

  dlls = vim.tbl_filter(function(path)
    return path:match "/bin/[Dd]ebug/" ~= nil or path:match "/bin/[Rr]elease/" ~= nil
  end, dlls)
  table.sort(dlls)

  if #dlls == 0 then
    return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/", "file")
  end

  if #dlls == 1 then
    return dlls[1]
  end

  local choices = {}
  for i, path in ipairs(dlls) do
    choices[i] = i .. ". " .. path
  end

  local choice = vim.fn.inputlist(choices)
  if choice >= 1 and choice <= #dlls then
    return dlls[choice]
  end
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

map({ "n", "v" }, "Q", function()
  dapui.eval()
end, { desc = "DAP: peek value" })
