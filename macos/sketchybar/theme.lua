local theme = {}

theme.colors = {
  bar = 0xff08080b,
  fg = 0xffc8d3f5,
  dim = 0x80c8d3f5,
  red = 0xffff757f,
  yellow = 0xffffc777,
}

local family = "JetBrainsMono Nerd Font"
theme.font = {
  text = { family = family, style = "Medium", size = 13.0 },
  icon = { family = family, style = "Regular", size = 14.0 },
}

theme.icons = {
  workspace_active = "\u{f14fb}",
  battery = {
    "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}",
    "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}",
  },
  battery_charging = {
    "\u{f089c}", "\u{f0086}", "\u{f0087}", "\u{f0088}", "\u{f089d}",
    "\u{f0089}", "\u{f089e}", "\u{f008a}", "\u{f008b}", "\u{f0085}",
  },
  volume = { "\u{f026}", "\u{f027}", "\u{f028}" },
  volume_muted = "\u{eee8}",
  wifi = "\u{f0928}",
  wifi_off = "\u{f092e}",
  vpn = "\u{f0565}",
  vpn_off = "\u{f099c}",
  cpu = "\u{f035b}",
  memory = "\u{f061a}",
}

function theme.level_color(percent, warn, critical)
  if percent >= critical then
    return theme.colors.red
  elseif percent >= warn then
    return theme.colors.yellow
  end
  return theme.colors.fg
end

return theme
