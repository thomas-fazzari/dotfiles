local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local i = ls.insert_node

ls.add_snippets("cs", {
  ls.snippet("/// summary", fmt(
    [[
///<summary>
/// {}
///</summary>
]],
    { i(1) }
  )),
})
