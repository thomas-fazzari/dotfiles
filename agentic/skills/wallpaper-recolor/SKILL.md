---
name: wallpaper-recolor
description: Recolor a wallpaper or any image to fit a color palette or theme (Tokyo Night, a theme of themes/, a list of hex colors). Use when the user asks to rework, recolor or match an image to a theme.
---

# Wallpaper recolor

`scripts/recolor.py SRC DST HEX... [options]` maps every color of `SRC` to a blend of the nearest palette colors in Oklab and writes `DST`.

1. Build the palette: the theme's backgrounds, foregrounds, grays and accents, taken from `themes/<name>/` (ghostty, nvim.lua) or the theme's upstream definition. Give enough dark tones, they carry most of a wallpaper. Pastel palettes need darker shades of their accents (red, orange) too, or the dark saturated parts of the image fall back to the blues.
2. Write to a copy in `wallpapers/` (`<original>-<theme>.png`), never over the original.
3. Preview with `magick DST -resize 1400x /tmp/preview.jpg`, read it, then tune and compare variants side by side when the target is unclear:

| Option          | Default | Effect                                                 |
| --------------- | ------- | ------------------------------------------------------ |
| `--sigma`       | 0.04    | Blending radius, higher is softer and more washed out  |
| `--lum-keep`    | 0.6     | Share of the original lightness kept, preserves detail |
| `--gamma`       | 1.0     | Above 1 darkens                                        |
| `--tint HEX`    | none    | Pushes the low-chroma tones towards this color's hue   |
| `--tint-amount` | 0.02    | Strength of the tint                                   |

A large gradient (sky, water) that snaps between two palette hues gets a hard edge: drop the hue it should not reach and raise `--sigma` (0.07 smooths it).

To make it a theme's wallpaper: `ln -sfn ../../wallpapers/<file> themes/<name>/wallpaper.<ext>` after removing any other `wallpaper.*` there, then `mise run wallpaper` if `themes/current` points to that theme.

Example, `wallpapers/wallhaven-vq72xm-tokyonight-moon.png`: the Tokyo Night Moon palette with `--gamma 1.2 --tint c099ff`.
