---@meta
error("Cannot require a meta file")


-- These node subclasses are not ready for public exposure as they are:
-- - not classic classes
-- - only used in a few locations: api.tree.get_nodes and UserDecorator

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
