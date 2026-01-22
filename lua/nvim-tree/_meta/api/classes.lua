---@meta

-- TODO #3088 document these

---@brief
---Classes shared by multiple API modules.
---

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
