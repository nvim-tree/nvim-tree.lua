-- TODO #3088 rename this to nvim-tree/api.lua

---@brief
---nvim-tree exposes a public API. This is non breaking, with additions made as necessary.
---
---Please do not require or use modules other than `nvim-tree.api`, as internal modules are not stable and will change without notice.
---
---The API is separated into multiple modules, which can be accessed via the parent `nvim-tree.api` or via `nvim-tree.api.<module>`. The following examples are equivalent:
---```lua
---
---local api = require("nvim-tree.api")
---api.tree.reload()
---
---local tree = require("nvim-tree.api.tree")
---tree.reload()
---```
---
---Generally, functions accepting {node} as their first argument will use the node under the cursor when that argument is not present or nil. e.g. the following are functionally identical:
---```lua
---
---api.node.open.edit(nil, { focus = true })
---
---api.node.open.edit(api.tree.get_node_under_cursor(), { focus = true })
---```

---
---Base Node, Abstract
---
---@class nvim_tree.api.Node
---@field type "file" | "directory" | "link" uv.fs_stat.result.type
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.fs_stat.result?
---@field git_status GitNodeStatus?
---@field hidden boolean
---@field name string
---@field parent nvim_tree.api.DirectoryNode?
---@field diag_severity lsp.DiagnosticSeverity?

---
---File
---
---@class nvim_tree.api.FileNode: nvim_tree.api.Node
---@field extension string

---
---Directory
---
---@class nvim_tree.api.DirectoryNode: nvim_tree.api.Node
---@field has_children boolean
---@field nodes nvim_tree.api.Node[]
---@field open boolean

---
---Root Directory
---
---@class nvim_tree.api.RootNode: nvim_tree.api.DirectoryNode

---
---Link mixin
---
---@class nvim_tree.api.LinkNode
---@field link_to string
---@field fs_stat_target uv.fs_stat.result

---
---File Link
---
---@class nvim_tree.api.FileLinkNode: nvim_tree.api.FileNode, nvim_tree.api.LinkNode

---
---DirectoryLink
---
---@class nvim_tree.api.DirectoryLinkNode: nvim_tree.api.DirectoryNode, nvim_tree.api.LinkNode

return {
  events = require("nvim-tree.api.events"),
  filter = require("nvim-tree.api.filter"),
  fs = require("nvim-tree.api.fs"),
  health = require("nvim-tree.api.health"),
  map = require("nvim-tree.api.map"),
  marks = require("nvim-tree.api.marks"),
  node = require("nvim-tree.api.node"),
  tree = require("nvim-tree.api.tree"),
}
