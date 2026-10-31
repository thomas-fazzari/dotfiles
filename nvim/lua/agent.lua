-- Line references and review comments sent to the agent of this Herdr space through hc.
local ns = vim.api.nvim_create_namespace "agent_comments"
local pending = {}

local function hc(args, on_done)
  vim.system(vim.list_extend({ "hc" }, args), { text = true }, function(r)
    vim.schedule(function()
      on_done(r)
    end)
  end)
end

-- hc reports failures as JSON on stderr when piped.
local function error_of(r)
  local ok, decoded = pcall(vim.json.decode, r.stderr)
  local message = ok and type(decoded) == "table" and decoded.error and decoded.error.message or vim.trim(r.stderr)
  vim.notify("agent: " .. message, vim.log.levels.ERROR)
end

-- Agents are the terminals of this space that report a status.
local function pick_agent(use)
  hc({ "get", vim.env.HC_TERMINAL_ID, "--json" }, function(me)
    if me.code ~= 0 then
      return error_of(me)
    end
    local space = (vim.json.decode(me.stdout).labels or {})["herdr.space"]
    if not space then
      return vim.notify("agent: this terminal is not in a Herdr space", vim.log.levels.WARN)
    end
    hc({ "ls", "--json", "--label", "herdr.space=" .. space }, function(ls)
      if ls.code ~= 0 then
        return error_of(ls)
      end
      local agents = vim.tbl_filter(function(t)
        return t.address ~= vim.env.HC_TERMINAL_ID and type(t.status) == "string"
      end, vim.json.decode(ls.stdout).terminals)
      if #agents == 0 then
        return vim.notify("agent: no agent in this space", vim.log.levels.WARN)
      elseif #agents == 1 then
        return use(agents[1])
      end
      vim.ui.select(agents, {
        prompt = "Agent",
        format_item = function(t)
          return string.format("%s · %s · %s", t.agent, t.status, t.where)
        end,
      }, function(t)
        if t then
          use(t)
        end
      end)
    end)
  end)
end

local function send(text, on_sent)
  pick_agent(function(agent)
    hc({ "send", agent.address, text }, function(r)
      if r.code ~= 0 then
        return error_of(r)
      end
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
    vim.notify("agent: sent " .. ref .. " to " .. agent.where)
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
    vim.notify(string.format("agent: sent %d comment(s) to %s", count, agent.where))
  end)
end

vim.keymap.set({ "n", "x" }, "<leader>ai", reference, { desc = "Agent: send line reference" })
vim.keymap.set({ "n", "x" }, "<leader>ac", comment, { desc = "Agent: comment" })
vim.keymap.set("n", "<leader>as", send_comments, { desc = "Agent: send comments" })
vim.keymap.set("n", "<leader>ad", discard, { desc = "Agent: discard comments" })
