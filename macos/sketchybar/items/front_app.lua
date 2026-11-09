local sbar = require("sketchybar")
local theme = require("theme")

local front_app = sbar.add("item", "front_app", {
  updates = true,
  padding_left = 14,
  icon = { drawing = false },
  label = { color = theme.colors.dim, padding_left = 0, max_chars = 40 },
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = env.INFO })
end)

sbar.exec("aerospace list-windows --focused --format '%{app-name}'", function(app)
  front_app:set({ label = tostring(app):match("^%s*(.-)%s*$") })
end)
