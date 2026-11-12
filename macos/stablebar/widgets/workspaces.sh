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
          focused: { width: 26, background: { light: "#2e7de9", dark: "#82aaff" } },
          occupied: {
            background: { light: "#6172b0", dark: "#828bb8" },
            states: { hover: { background: { light: "#3760bf", dark: "#c8d3f5" } } }
          },
          empty: {
            background: { light: "#a8aecb", dark: "#444a73" },
            states: { hover: { background: { light: "#6172b0", dark: "#828bb8" } } }
          }
        }
      }'
