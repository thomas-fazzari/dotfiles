return {
  -- Hover comes from basedpyright
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
  end,
}
