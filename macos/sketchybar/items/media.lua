local sbar = require("sketchybar")

local MAX_CHARS = 40

sbar.add("event", "now_playing_change")

local media = sbar.add("item", "media", {
  position = "right",
  drawing = false,
  padding_right = 14,
  updates = true,
  icon = { drawing = false },
  label = { padding_left = 0, max_chars = MAX_CHARS },
})

local function update()
  sbar.exec("media-control get --no-artwork", function(now)
    if type(now) ~= "table" or not now.title or not now.playing then
      media:set({ drawing = false })
      return
    end
    local text = now.title
    if now.artist and now.artist ~= "" and (utf8.len(text .. now.artist) or math.huge) <= MAX_CHARS - 3 then
      text = text .. " · " .. now.artist
    end
    media:set({ drawing = true, label = text })
  end)
end

media:subscribe("now_playing_change", update)
media:subscribe("mouse.clicked", function(env)
  sbar.exec("media-control " .. (env.BUTTON == "right" and "next-track" or "toggle-play-pause"))
end)

sbar.exec(os.getenv("CONFIG_DIR") .. "/helpers/now_playing.sh")
update()
