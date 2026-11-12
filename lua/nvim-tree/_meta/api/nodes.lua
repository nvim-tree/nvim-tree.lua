---@meta

---@brief
---The [nvim_tree.api.Node] classes represent a single entry in the tree: a file or a folder.
---
---[nvim_tree.api.Node] and [nvim_tree.api.LinkNode] are abstract, you will always be provided with a concrete implementation.
---
---Instances may be provided by API functions for use as a:
---- handle to pass back to API functions e.g. [nvim_tree.api.node.run.cmd()]
---- reference in callbacks e.g. [nvim_tree.config.sort.Sorter] {sorter}
---
---Please do not mutate the contents of any [nvim_tree.api.Node] object.

local Class = require("nvim-tree.classic")

local nvim_tree = { api = {} }

---
---Abstract node
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
nvim_tree.api.Node = Class:extend()

---
---Single directory which may contain children
---
---@class nvim_tree.api.DirectoryNode: nvim_tree.api.Node
---@field has_children boolean child {nodes} are present
---@field nodes nvim_tree.api.Node[] child nodes
---@field open boolean directory is open
nvim_tree.api.DirectoryNode = nvim_tree.api.Node:extend()

---
---The directory that is the root of the tree
---
---@class nvim_tree.api.RootNode: nvim_tree.api.DirectoryNode
nvim_tree.api.RootNode = nvim_tree.api.DirectoryNode:extend()

---
---Single file
---
---@class nvim_tree.api.FileNode: nvim_tree.api.Node
---@field extension string
nvim_tree.api.FileNode = nvim_tree.api.Node:extend()


---
---Abstract link
---
---@class nvim_tree.api.LinkNode: nvim_tree.Class
---@field link_to string absolute path of the file or directory linked to
---@field fs_stat_target uv.fs_stat.result stat of the linked file or directory
nvim_tree.api.LinkNode = Class:extend()


---
---Link to a directory containing additional [nvim_tree.api.LinkNode] data
---
---@class nvim_tree.api.DirectoryLinkNode: nvim_tree.api.DirectoryNode, nvim_tree.api.LinkNode
nvim_tree.api.DirectoryLinkNode = nvim_tree.api.DirectoryNode:extend()
nvim_tree.api.DirectoryLinkNode:implement(nvim_tree.api.LinkNode)


---
---Link to a file containing additional [nvim_tree.api.LinkNode] data
---
---@class nvim_tree.api.FileLinkNode: nvim_tree.api.FileNode, nvim_tree.api.LinkNode
nvim_tree.api.FileLinkNode = nvim_tree.api.FileNode:extend()
nvim_tree.api.FileLinkNode:implement(nvim_tree.api.LinkNode)


---
---Git statuses for a single [nvim_tree.api.Node].
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

return nvim_tree.api
