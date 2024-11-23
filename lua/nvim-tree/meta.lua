---@meta

--
-- Nodes
--

---@class (exact) nvim_tree.api.Node: Class
---@field type "file" | "directory" | "link" uv.fs_stat.result.type
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.fs_stat.result?
---@field git_status GitNodeStatus?
---@field hidden boolean
---@field name string
---@field parent nvim_tree.api.DirectoryNode?
---@field diag_severity lsp.DiagnosticSeverity?

---@class (exact) nvim_tree.api.FileNode: nvim_tree.api.Node
---@field extension string

---@class (exact) nvim_tree.api.DirectoryNode: nvim_tree.api.Node
---@field has_children boolean
---@field nodes nvim_tree.api.Node[]
---@field open boolean

---@class (exact) nvim_tree.api.RootNode: nvim_tree.api.DirectoryNode

---@class (exact) nvim_tree.api.LinkNode: Class
---@field link_to string
---@field fs_stat_target uv.fs_stat.result

---@class (exact) nvim_tree.api.FileLinkNode: nvim_tree.api.FileNode, nvim_tree.api.LinkNode

---@class (exact) nvim_tree.api.DirectoryLinkNode: nvim_tree.api.DirectoryNode, nvim_tree.api.LinkNode

--
-- Decorators
--

---Highlight group range as per nvim-tree.renderer.highlight_*
---@alias DecoratorHighlightRange "none" | "icon" | "name" | "all"

---Icon position as per renderer.icons.*_placement
---@alias DecoratorIconPlacement "none" | "before" | "after" | "signcolumn" | "right_align"

---Decorator Constructor Arguments
---@class (exact) DecoratorArgs
---@field enabled boolean
---@field highlight_range DecoratorHighlightRange
---@field icon_placement DecoratorIconPlacement

--
-- Types
--

---A string for rendering, with optional highlight groups to apply to it
---@class (exact) HighlightedString
---@field str string
---@field hl string[]
