local sbar = require("sketchybar")
local theme = require("theme")

local workspace_ids = { "1", "2", "3", "4" }

sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "aerospace_windows_change")

local spaces = {}
for _, id in ipairs(workspace_ids) do
  local space = sbar.add("item", "space." .. id, {
    padding_left = 1,
    padding_right = 1,
    icon = { string = id, font = theme.font.text, width = 22, align = "center" },
    label = { drawing = false },
  })
  space:subscribe("mouse.clicked", function()
    sbar.exec("aerospace workspace " .. id)
  end)
  spaces[id] = space
end

local function render(focused, occupied)
  for id, space in pairs(spaces) do
    space:set({
      icon = {
        string = id == focused and theme.icons.workspace_active or id,
        color = (id == focused or occupied[id]) and theme.colors.fg or theme.colors.dim,
      },
    })
  end
end

local query = "aerospace list-workspaces --focused; echo ---; aerospace list-workspaces --monitor all --empty no"

local function refresh()
  sbar.exec(query, function(output)
    local focused, rest = tostring(output):match("^(%S*)%s*%-%-%-(.*)$")
    local occupied = {}
    for id in (rest or ""):gmatch("%S+") do
      occupied[id] = true
    end
    render(focused, occupied)
  end)
end

local observer = sbar.add("item", { drawing = false, updates = true })
observer:subscribe(
  { "aerospace_workspace_change", "aerospace_windows_change", "front_app_switched", "space_windows_change", "system_woke" },
  refresh
)
refresh()
