#!/bin/sh
# Script colors cannot use tokens, so the theme's stablebar.json passes them as WS_* variables
occupied=$(aerospace list-windows --all --format '%{workspace}' | sort -u)

aerospace list-workspaces --all --json --format '%{workspace} %{workspace-is-focused}' |
  jq -c --arg occupied "$occupied" '
    ($occupied | split("\n")) as $busy
    | {
        text: "Workspaces",
        lists: {
          spaces: map(.workspace as $name | {
            dot: " ",
            command: "aerospace workspace \($name | @sh)",
            style: (if ."workspace-is-focused" then "focused"
                    elif any($busy[]; . == $name) then "occupied"
                    else "empty" end)
          })
        },
        styles: {
          focused: { width: 26, background: $ENV.WS_FOCUSED },
          occupied: {
            background: $ENV.WS_OCCUPIED,
            states: { hover: { background: $ENV.WS_HOVER } }
          },
          empty: {
            background: $ENV.WS_EMPTY,
            states: { hover: { background: $ENV.WS_OCCUPIED } }
          }
        }
      }'
