local Class = require("nvim-tree.classic")

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

  Decorator = require("nvim-tree._meta.api.decorator"),

  decorator = require("nvim-tree._meta.api.deprecated").decorator, ---@deprecated
  diagnostics = require("nvim-tree._meta.api.deprecated").diagnostics, ---@deprecated
  live_filter = require("nvim-tree._meta.api.deprecated").live_filter, ---@deprecated
}


---The Node class is an abstract data class with many implementations.
---Instances may be provided by API functions for use as a:
---- handle to pass back to API functions e.g. [nvim_tree.api.node.run.cmd()]
---- reference in callbacks e.g. [nvim_tree.config.sort.Sorter] {sorter}
---
---Please do not mutate the contents of any Node object.
---
---@class nvim_tree.api.Node: nvim_tree.Class
---@field absolute_path string of the file or directory
---@field name string file or directory name
---@field parent? nvim_tree.api.DirectoryNode parent directory, nil for root
---@field type "file" | "directory" | "link" [uv.fs_stat()] {type}
---@field executable boolean file is executable
---@field fs_stat? uv.fs_stat.result at time of last tree display, see [uv.fs_stat()]
---@field git_status nvim_tree.git.Status? for files and directories
---@field diag_severity? lsp.DiagnosticSeverity diagnostic status
---@field hidden boolean node is not visible in the tree
---@field uid_node number internal use only
api.Node = Class:extend()

---
---Directory
---
---@class nvim_tree.api.DirectoryNode: nvim_tree.api.Node
---@field has_children boolean child {nodes} are present
---@field nodes nvim_tree.api.Node[] child nodes
---@field open boolean directory is open
api.DirectoryNode = api.Node:extend()

---
---Root Directory
---
---@class nvim_tree.api.RootNode: nvim_tree.api.DirectoryNode
api.RootNode = api.DirectoryNode:extend()

---
---File
---
---@class nvim_tree.api.FileNode: nvim_tree.api.Node
---@field extension string
api.FileNode = api.Node:extend()


---
---Abstract Link
---
---@class nvim_tree.api.LinkNode: nvim_tree.Class
---@field link_to string absolute path of the file or directory linked to
---@field fs_stat_target uv.fs_stat.result stat of the linked file or directory
api.LinkNode = Class:extend()


---
---Directory Link
---
---@class nvim_tree.api.DirectoryLinkNode: nvim_tree.api.DirectoryNode, nvim_tree.api.LinkNode
api.DirectoryLinkNode = api.DirectoryNode:extend()
api.DirectoryLinkNode:implement(api.LinkNode)


---
---File Link
---
---@class nvim_tree.api.FileLinkNode: nvim_tree.api.FileNode, nvim_tree.api.LinkNode
api.FileLinkNode = api.FileNode:extend()
api.FileLinkNode:implement(api.LinkNode)


---
---Git statuses for a single node.
---
---`nvim_tree.git.XY`: 2 character string, see `man 1 git-status` "Short Format"
---@alias nvim_tree.git.XY string
---
---{dir} status is derived from its contents:
---- `direct`: inherited from child files
---- `indirect`: inherited from child directories
---
---@class nvim_tree.git.Status
---@field file? nvim_tree.git.XY status of a file node
---@field dir? table<"direct" | "indirect", nvim_tree.git.XY[]> direct inclusive-or indirect status

require("nvim-tree.api.impl").hydrate_pre_setup(api)

return api
