-- global
rex.bind("cmd+w", "client.tab.close")
rex.bind("shift+cmd+right", "client.tab.next")
rex.bind("shift+cmd+left", "client.tab.previous")
rex.bind("shift+cmd+down", "session.next")
rex.bind("shift+cmd+up", "session.previous")
rex.bind("cmd+n", "session.new")
rex.bind("shift+cmd+w", "pane.close")
rex.bind("f2", "client.tab.rename")
rex.bind("shift+f2", "session.rename")
rex.bind("cmd+9", "client.tab.goto", { index = 9 })

-- terminal
rex.bind("cmd+c", "pane.copy")
rex.bind("cmd+v", "pane.paste")
rex.bind("alt+backspace", "pane.send_key", { key = "ctrl+w" })
