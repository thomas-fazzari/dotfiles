local sbar = require("sketchybar")
local theme = require("theme")

local colors, icons = theme.colors, theme.icons

local function settings(pane)
  return function()
    sbar.exec("open 'x-apple.systempreferences:" .. pane .. "'")
  end
end

local function open_btop()
  sbar.exec("open -na Ghostty --args -e /opt/homebrew/bin/btop")
end

local battery = sbar.add("item", "battery", { position = "right", update_freq = 60 })
local memory = sbar.add("item", "memory", { position = "right", update_freq = 15, icon = icons.memory })
local cpu = sbar.add("item", "cpu", { position = "right", update_freq = 5, icon = icons.cpu })
local volume = sbar.add("item", "volume", { position = "right", label = { drawing = false } })
local wifi = sbar.add("item", "wifi", { position = "right", update_freq = 30, label = { drawing = false } })
local vpn = sbar.add("item", "vpn", { position = "right", update_freq = 15, label = { drawing = false } })

local function update_battery()
  sbar.exec("pmset -g batt", function(output)
    local result = tostring(output)
    local percent = tonumber(result:match("(%d+)%%"))
    if not percent then
      battery:set({ drawing = false })
      return
    end
    local on_ac = result:find("AC Power") ~= nil
    local level = math.max(1, math.ceil(percent / 10))
    local color = (not on_ac and percent <= 10 and colors.red) or (not on_ac and percent <= 20 and colors.yellow) or colors.fg
    battery:set({
      icon = { string = (on_ac and icons.battery_charging or icons.battery)[level], color = color },
      label = { string = percent .. "%", color = color, drawing = not on_ac and percent <= 20 },
    })
  end)
end

battery:subscribe({ "routine", "power_source_change", "system_woke" }, update_battery)
battery:subscribe("mouse.clicked", settings("com.apple.Battery-Settings.extension"))
update_battery()

local function update_cpu()
  sbar.exec("iostat -c 2 -w 1 -n 0 | tail -1", function(output)
    local user, system = tostring(output):match("^%s*(%d+)%s+(%d+)")
    if user then
      local load = tonumber(user) + tonumber(system)
      cpu:set({ label = { string = load .. "%", color = theme.level_color(load, 50, 80) } })
    end
  end)
end

local function update_memory()
  sbar.exec("memory_pressure -Q", function(output)
    local free = tonumber(tostring(output):match("(%d+)%%"))
    if free then
      memory:set({ label = { string = 100 - free .. "%", color = theme.level_color(100 - free, 70, 85) } })
    end
  end)
end

cpu:subscribe({ "routine", "system_woke" }, update_cpu)
memory:subscribe({ "routine", "system_woke" }, update_memory)
cpu:subscribe("mouse.clicked", open_btop)
memory:subscribe("mouse.clicked", open_btop)
update_cpu()
update_memory()

local function show_volume(level)
  sbar.exec("osascript -e 'output muted of (get volume settings)'", function(muted)
    local is_muted = tostring(muted):find("true") ~= nil or level == 0
    volume:set({
      icon = {
        string = is_muted and icons.volume_muted or icons.volume[level < 34 and 1 or level < 67 and 2 or 3],
        color = is_muted and colors.dim or colors.fg,
      },
    })
  end)
end

local function update_volume()
  sbar.exec("osascript -e 'output volume of (get volume settings)'", function(level)
    show_volume(tonumber(tostring(level):match("%d+")) or 0)
  end)
end

volume:subscribe("volume_change", function(env)
  show_volume(tonumber(env.INFO) or 0)
end)
volume:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    sbar.exec("osascript -e 'set volume output muted not (output muted of (get volume settings))'", update_volume)
  else
    settings("com.apple.Sound-Settings.extension")()
  end
end)
volume:subscribe("mouse.scrolled", function(env)
  local step = (tonumber(env.SCROLL_DELTA) or 0) > 0 and 5 or -5
  sbar.exec("osascript -e 'set volume output volume (output volume of (get volume settings) + " .. step .. ")'")
end)
update_volume()

local function update_wifi()
  sbar.exec("ipconfig getifaddr en0", function(address)
    local connected = tostring(address):match("%d+%.%d+%.%d+%.%d+") ~= nil
    wifi:set({ icon = { string = connected and icons.wifi or icons.wifi_off, color = connected and colors.fg or colors.dim } })
  end)
end

wifi:subscribe({ "routine", "wifi_change", "system_woke" }, update_wifi)
wifi:subscribe("mouse.clicked", settings("com.apple.wifi-settings-extension"))
update_wifi()

local function update_vpn()
  sbar.exec("scutil --nc list; command -v mullvad >/dev/null && mullvad status", function(output)
    local connected = false
    for line in tostring(output):gmatch("[^\n]+") do
      connected = connected or line:find("%(Connected%)") ~= nil or line:match("^Connected") ~= nil
    end
    vpn:set({ icon = { string = connected and icons.vpn or icons.vpn_off, color = connected and colors.fg or colors.dim } })
  end)
end

vpn:subscribe({ "routine", "wifi_change", "system_woke" }, update_vpn)
vpn:subscribe("mouse.clicked", settings("com.apple.NetworkExtensionSettingsUI.NESettingsUIExtension"))
update_vpn()
