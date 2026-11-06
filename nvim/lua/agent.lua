-- Line references and review comments sent to the agent of this Rex session.
local ns = vim.api.nvim_create_namespace "agent_comments"
local pending = {}

-- Run by `rex do` against this session: the other terminals whose foreground program is an agent.
local list_agents = [[
local agents = { pi = true, claude = true, codex = true, opencode = true }
local view = assert(rex.session.view {})
local found = {}
for _, window in ipairs(view.windows) do
  for _, layer in ipairs(window.layers) do
    for _, block in ipairs(layer.blocks) do
      if block.block_id ~= rex.block_id then
        local process = rex.block.call("com.superlogical.terminal", "process", { block_id = block.block_id })
        local name = process and process.foreground and process.foreground.name
        if agents[name] then
          table.insert(found, { block = block.block_id, agent = name, tab = window.label })
        end
      end
    end
  end
end
return found
]]

-- Pasted rather than typed, so a multiline message is not submitted line by line.
local paste_and_submit = [[
assert(rex.call("block.event", {
  session_id = rex.session_id,
  block_id = rex.args.block,
  event = { type = "paste", payload = { text = rex.args.text } },
}))
assert(rex.block.call("com.superlogical.terminal", "write", { block_id = rex.args.block, data = "\r" }))
]]

local function rex_do(code, args, on_done)
  local cmd = { "rex", "do", "-s", vim.env.REX_SESSION, "-b", vim.env.REX_BLOCK, "-e", code, "--json" }
  if args then
    vim.list_extend(cmd, { "--args", vim.json.encode(args) })
  end
  vim.system(cmd, { text = true }, function(r)
    vim.schedule(function()
      if r.code ~= 0 then
        return vim.notify("agent: " .. vim.trim(r.stderr), vim.log.levels.ERROR)
      end
      on_done(r.stdout)
    end)
  end)
end

local function pick_agent(use)
  rex_do(list_agents, nil, function(stdout)
    local ok, agents = pcall(vim.json.decode, stdout)
    if not ok or type(agents) ~= "table" or #agents == 0 then
      return vim.notify("agent: no agent in this session", vim.log.levels.WARN)
    elseif #agents == 1 then
      return use(agents[1])
    end
    vim.ui.select(agents, {
      prompt = "Agent",
      format_item = function(a)
        return string.format("%s · %s", a.agent, a.tab)
      end,
    }, function(a)
      if a then
        use(a)
      end
    end)
  end)
end

local function send(text, on_sent)
  pick_agent(function(agent)
    rex_do(paste_and_submit, { block = agent.block, text = text }, function()
      on_sent(agent)
    end)
  end)
end

local function location(buf, first, last)
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":.")
  return path .. ":" .. first .. (last > first and "-" .. last or "")
end

-- The current line, or the selection (leaving visual mode).
local function lines()
  local first, last = vim.fn.line "v", vim.fn.line "."
  if vim.fn.mode():match "[vV\22]" then
    vim.api.nvim_feedkeys(vim.keycode "<Esc>", "nx", false)
  end
  return math.min(first, last), math.max(first, last)
end

local function reference()
  local first, last = lines()
  local ref = location(0, first, last)
  send(ref, function(agent)
    vim.notify("agent: sent " .. ref .. " to " .. agent.agent .. " in " .. agent.tab)
  end)
end

local function comment()
  local buf = vim.api.nvim_get_current_buf()
  local first, last = lines()
  vim.ui.input({ prompt = "Comment: " }, function(text)
    if not text or text == "" then
      return
    end
    local mark = vim.api.nvim_buf_set_extmark(buf, ns, first - 1, 0, {
      end_row = last - 1,
      virt_text = { { "● " .. text, "DiagnosticInfo" } },
      virt_text_pos = "eol",
    })
    table.insert(pending, { buf = buf, mark = mark, text = text })
  end)
end

local function discard()
  for _, c in ipairs(pending) do
    pcall(vim.api.nvim_buf_del_extmark, c.buf, ns, c.mark)
  end
  pending = {}
end

-- Extmarks follow edits, so locations are read at send time.
local function send_comments()
  if #pending == 0 then
    return vim.notify "agent: no comments"
  end
  local message = { "Review comments:" }
  for _, c in ipairs(pending) do
    local mark = vim.api.nvim_buf_get_extmark_by_id(c.buf, ns, c.mark, { details = true })
    table.insert(message, string.format("- %s: %s", location(c.buf, mark[1] + 1, mark[3].end_row + 1), c.text))
  end
  local count = #pending
  send(table.concat(message, "\n"), function(agent)
    discard()
    vim.notify(string.format("agent: sent %d comment(s) to %s in %s", count, agent.agent, agent.tab))
  end)
end

vim.keymap.set({ "n", "x" }, "<leader>ai", reference, { desc = "Agent: send line reference" })
vim.keymap.set({ "n", "x" }, "<leader>ac", comment, { desc = "Agent: comment" })
vim.keymap.set("n", "<leader>as", send_comments, { desc = "Agent: send comments" })
vim.keymap.set("n", "<leader>ad", discard, { desc = "Agent: discard comments" })
