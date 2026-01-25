---@meta
error("Cannot require a meta file")

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


---The Node class is a data class. Instances may be provided by API functions for use as a:
---- handle to pass back to API functions e.g. [nvim_tree.api.node.run.cmd()]
---- reference in callbacks e.g. [nvim_tree.config.sort.Sorter] {sorter}
---
---Please do not mutate the contents of any Node object.
---
---@class nvim_tree.api.Node
---@field absolute_path string of the file or directory
---@field name string file or directory name
---@field parent? nvim_tree.api.DirectoryNode parent directory, nil for root
---@field type "file" | "directory" | "link" [uv.fs_stat()] {type}
---@field executable boolean file is executable
---@field fs_stat? uv.fs_stat.result at time of last tree display, see [uv.fs_stat()]
---@field git_status nvim_tree.git.Status? for files and directories
---@field diag_severity? lsp.DiagnosticSeverity diagnostic status
---@field hidden boolean node is not visible in the tree


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




-- Following are exact as that prevents them from having documentation generated.
-- They are not ready for public exposure as:
-- - They are not classic classes
-- - They are only used in a few locations: api.tree.get_nodes and UserDecorator

---
---File
---
---@class (exact) nvim_tree.api.FileNode: nvim_tree.api.Node
---@field extension string

---
---Directory
---
---@class (exact) nvim_tree.api.DirectoryNode: nvim_tree.api.Node
---@field has_children boolean
---@field nodes nvim_tree.api.Node[]
---@field open boolean

---
---Root Directory
---
---@class (exact) nvim_tree.api.RootNode: nvim_tree.api.DirectoryNode

---
---Link mixin
---
---@class (exact) nvim_tree.api.LinkNode
---@field link_to string
---@field fs_stat_target uv.fs_stat.result

---
---File Link
---
---@class (exact) nvim_tree.api.FileLinkNode: nvim_tree.api.FileNode, nvim_tree.api.LinkNode

---
---DirectoryLink
---
---@class (exact) nvim_tree.api.DirectoryLinkNode: nvim_tree.api.DirectoryNode, nvim_tree.api.LinkNode
