#!/bin/sh
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
          focused: { width: 26, background: { light: "#3a3a38", dark: "#d6d6d4" } },
          occupied: {
            background: { light: "#6b6b69", dark: "#8e8e8c" },
            states: { hover: { background: { light: "#1f1f1f", dark: "#e4e4e2" } } }
          },
          empty: {
            background: { light: "#b5b5b3", dark: "#454543" },
            states: { hover: { background: { light: "#6b6b69", dark: "#8e8e8c" } } }
          }
        }
      }'
