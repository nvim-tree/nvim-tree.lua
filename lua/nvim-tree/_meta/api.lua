---@meta
error("Cannot require a meta file")

--
-- API Options
--

---@class (exact) nvim_tree.api.TreeOpenOpts
---@field path? string root directory for the tree
---@field current_window? boolean open the tree in the current window
---@field winid? number open the tree in the specified winid, overrides current_window
---@field find_file? boolean find the current buffer
---@field update_root? boolean requires find_file, see [nvim-tree.update_focused_file.update_root]
---@field focus? boolean focus the tree when opening, default true

---@class (exact) nvim_tree.api.TreeToggleOpts
---@field path? string root directory for the tree
---@field current_window? boolean open the tree in the current window
---@field winid? number open the tree in the specified [winid], overrides current_window
---@field find_file? boolean find the current buffer
---@field update_root? boolean requires find_file, see [nvim-tree.update_focused_file.update_root]
---@field focus? boolean focus the tree when opening, default true

---@class (exact) nvim_tree.api.TreeResizeOpts
---@field width? string|function|number|table new [nvim-tree.view.width] value
---@field absolute? number set the width
---@field relative? number relative width adjustment

---@class (exact) nvim_tree.api.TreeFindFileOpts
---@field buf? string|number absolute/relative path OR bufnr to find
---@field open? boolean open the tree if necessary
---@field current_window? boolean requires open, open in the current window
---@field winid? number open the tree in the specified [winid], overrides current_window
---@field update_root? boolean see [nvim-tree.update_focused_file.update_root]
---@field focus? boolean focus the tree

---@class (exact) nvim_tree.api.CollapseOpts
---@field keep_buffers? boolean do not collapse nodes with open buffers

---@class (exact) nvim_tree.api.TreeExpandOpts
---@field expand_until? (fun(expansion_count: integer, node: Node): boolean) Return true if node should be expanded. expansion_count is the total number of folders expanded.

---@class (exact) nvim_tree.api.TreeIsVisibleOpts
---@field tabpage? number as per [nvim_get_current_tabpage()]
---@field any_tabpage? boolean visible on any tab, default false

---@class (exact) nvim_tree.api.TreeWinIdOpts
---@field tabpage? number tabpage, 0 or nil for current, default nil

---@class (exact) nvim_tree.api.NodeEditOpts
---@field quit_on_open? boolean quits the tree when opening the file
---@field focus? boolean keep focus in the tree when opening the file

---@class (exact) nvim_tree.api.NodeBufferOpts
---@field force? boolean delete/wipe even if buffer is modified, default false

--
-- Nodes
--

---Base Node, Abstract
---@class (exact) nvim_tree.api.Node
---@field type "file" | "directory" | "link" uv.fs_stat.result.type
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.fs_stat.result?
---@field git_status GitNodeStatus?
---@field hidden boolean
---@field name string
---@field parent nvim_tree.api.DirectoryNode?
---@field diag_severity lsp.DiagnosticSeverity?

---File
---@class (exact) nvim_tree.api.FileNode: nvim_tree.api.Node
---@field extension string

---Directory
---@class (exact) nvim_tree.api.DirectoryNode: nvim_tree.api.Node
---@field has_children boolean
---@field nodes nvim_tree.api.Node[]
---@field open boolean

---Root Directory
---@class (exact) nvim_tree.api.RootNode: nvim_tree.api.DirectoryNode

---Link mixin
---@class (exact) nvim_tree.api.LinkNode
---@field link_to string
---@field fs_stat_target uv.fs_stat.result

---File Link
---@class (exact) nvim_tree.api.FileLinkNode: nvim_tree.api.FileNode, nvim_tree.api.LinkNode

---DirectoryLink
---@class (exact) nvim_tree.api.DirectoryLinkNode: nvim_tree.api.DirectoryNode, nvim_tree.api.LinkNode

--
-- Various Types
--

---A string for rendering, with optional highlight groups to apply to it
---@class (exact) nvim_tree.api.HighlightedString
---@field str string
---@field hl string[]
