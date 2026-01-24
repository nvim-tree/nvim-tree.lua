local api = {}

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
---Generally, functions accepting a [nvim_tree.api.Node] as their first argument will use the node under the cursor when that argument is not present or nil. e.g. the following are functionally identical:
---```lua
---
---api.node.open.edit(nil, { focus = true })
---
---api.node.open.edit(api.tree.get_node_under_cursor(), { focus = true })
---```


--
-- Load the (empty) meta definitions
--
api.commands = require("nvim-tree._meta.api.commands")
api.events = require("nvim-tree._meta.api.events")
api.filter = require("nvim-tree._meta.api.filter")
api.fs = require("nvim-tree._meta.api.fs")
api.health = require("nvim-tree._meta.api.health")
api.map = require("nvim-tree._meta.api.map")
api.marks = require("nvim-tree._meta.api.marks")
api.node = require("nvim-tree._meta.api.node")
api.tree = require("nvim-tree._meta.api.tree")


--
-- Map implementations
--
require("nvim-tree.api.impl.pre")(api)

return api
