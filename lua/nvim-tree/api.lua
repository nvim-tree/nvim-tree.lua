---@brief
---nvim-tree exposes a public API. This is non breaking, with additions made as necessary.
---
---Please do not require or use modules other than `nvim-tree.api`, as internal modules will change without notice.
---
---The API is separated into multiple modules:
---
---- [nvim-tree-api-appearance]
---- [nvim-tree-api-commands]
---- [nvim-tree-api-events]
---- [nvim-tree-api-filter]
---- [nvim-tree-api-fs]
---- [nvim-tree-api-git]
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
---Generally, functions accepting a [nvim_tree.api.Node] as their first argument will use the node under the cursor when that argument is not present or nil. Some functions are mode-dependent: when invoked in visual mode they will operate on all nodes in the visual selection instead of a single node. See |nvim-tree-mappings-default| for which mappings support visual mode.
---
---e.g. the following are functionally identical:
---```lua
---
---api.node.open.edit(nil, { focus = true })
---
---api.node.open.edit(api.tree.get_node_under_cursor(), { focus = true })
---```


---
---nvim-tree Public API
---
---@class nvim_tree.api
---@nodoc
local api = {
  appearance = require("nvim-tree._meta.api.appearance"),
  commands = require("nvim-tree._meta.api.commands"),
  config = require("nvim-tree._meta.api.config"),
  events = require("nvim-tree._meta.api.events"),
  filter = require("nvim-tree._meta.api.filter"),
  fs = require("nvim-tree._meta.api.fs"),
  git = require("nvim-tree._meta.api.git"),
  map = require("nvim-tree._meta.api.map"),
  marks = require("nvim-tree._meta.api.marks"),
  node = require("nvim-tree._meta.api.node"),
  tree = require("nvim-tree._meta.api.tree"),

  Node = require("nvim-tree._meta.api.nodes").Node,
  DirectoryNode = require("nvim-tree._meta.api.nodes").DirectoryNode,
  RootNode = require("nvim-tree._meta.api.nodes").RootNode,
  FileNode = require("nvim-tree._meta.api.nodes").FileNode,
  LinkNode = require("nvim-tree._meta.api.nodes").LinkNode,
  DirectoryLinkNode = require("nvim-tree._meta.api.nodes").DirectoryLinkNode,
  FileLinkNode = require("nvim-tree._meta.api.nodes").FileLinkNode,

  Decorator = require("nvim-tree._meta.api.decorator"),

  decorator = require("nvim-tree._meta.api.deprecated").decorator, ---@deprecated
  diagnostics = require("nvim-tree._meta.api.deprecated").diagnostics, ---@deprecated
  live_filter = require("nvim-tree._meta.api.deprecated").live_filter, ---@deprecated
}


require("nvim-tree.api.impl").hydrate_pre_setup(api)

return api
