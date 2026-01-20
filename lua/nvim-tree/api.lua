---@brief
---nvim-tree exposes a public API. This is non breaking, with additions made as necessary.
---
---Please do not require or use modules other than `nvim-tree.api`, as internal modules will change without notice.
---
---The API is separated into multiple modules:
---
---- [nvim-tree-api-commands]
---- [nvim-tree-api-events]
---- [nvim-tree-api-filter]
---- [nvim-tree-api-fs]
---- [nvim-tree-api-health]
---- [nvim-tree-api-map]
---- [nvim-tree-api-marks]
---- [nvim-tree-api-node]
---- [nvim-tree-api-tree]
---
---Modules are accessed via `api.<module>.<function>`
---
---Example invocation of the `reload` function in the `tree` module:
---```lua
---
---local api = require("nvim-tree.api")
---api.tree.reload()
---```
---Generally, functions accepting a {node} as their first argument will use the node under the cursor when that argument is not present or nil. e.g. the following are functionally identical:
---```lua
---
---api.node.open.edit(nil, { focus = true })
---
---api.node.open.edit(api.tree.get_node_under_cursor(), { focus = true })
---```


--
--Load the (empty) meta definitions
--
local api = {
  commands = require("nvim-tree._meta.api.commands"),
  events = require("nvim-tree._meta.api.events"),
  filter = require("nvim-tree._meta.api.filter"),
  fs = require("nvim-tree._meta.api.fs"),
  health = require("nvim-tree._meta.api.health"),
  map = require("nvim-tree._meta.api.map"),
  marks = require("nvim-tree._meta.api.marks"),
  node = require("nvim-tree._meta.api.node"),
  tree = require("nvim-tree._meta.api.tree"),
}


--
--Hydrate the implementations
--
require("nvim-tree.api-impl")(api)

return api
