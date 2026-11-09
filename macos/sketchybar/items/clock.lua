local sbar = require("sketchybar")

os.setlocale("fr_FR.UTF-8", "time")

local day = sbar.add("item", "clock.day", {
  position = "q",
  update_freq = 10,
  icon = { drawing = false },
  label = { padding_left = 0 },
})

local time = sbar.add("item", "clock.time", {
  position = "e",
  icon = { drawing = false },
  label = { padding_left = 0 },
})

local function update()
  day:set({ label = os.date("%A") })
  time:set({ label = os.date("%H:%M") })
end

day:subscribe({ "routine", "system_woke" }, update)
update()
