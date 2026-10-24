#!/usr/bin/env bash
set -euo pipefail

shortcut() { kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "$1" "$2,$3,$4"; }

kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true

for side in Left Right Top Bottom Between; do
  kwriteconfig6 --file kwinrc --group Script-krohnkite --key "screenGap$side" 8
done

while read -r name key default label; do
  shortcut "$name" "$key" "$default" "Krohnkite: $label"
done <<'EOF'
KrohnkiteFocusLeft Alt+H Meta+H Focus Left
KrohnkiteFocusDown Alt+J Meta+J Focus Down
KrohnkiteFocusUp Alt+K Meta+K Focus Up
KrohnkiteFocusRight Alt+L Meta+L Focus Right
KrohnkiteShiftLeft Alt+Shift+H Meta+Shift+H Move Left
KrohnkiteShiftDown Alt+Shift+J Meta+Shift+J Move Down/Next
KrohnkiteShiftUp Alt+Shift+K Meta+Shift+K Move Up/Prev
KrohnkiteShiftRight Alt+Shift+L Meta+Shift+L Move Right
KrohnkiteShrinkWidth Alt+- Meta+Ctrl+H Shrink Width
KrohnkitegrowWidth Alt+= Meta+Ctrl+L Grow Width
KrohnkiteToggleFloat Alt+Space Meta+F Toggle Float
KrohnkiteDecrease none Meta+D Decrease
KrohnkiteTileLayout none Meta+T Tile Layout
EOF

symbols=('&' 'é' '"' "'")
for n in 1 2 3 4; do
  shortcut "Switch to Desktop $n" "Alt+$n"$'\t'"Alt+${symbols[n - 1]}" "Ctrl+F$n"$'\t'"Meta+F$n" "Switch to Desktop $n"
  shortcut "Window to Desktop $n" "Alt+Shift+$n" none "Window to Desktop $n"
done
