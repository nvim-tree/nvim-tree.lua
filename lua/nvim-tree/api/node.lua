---@meta
local nvim_tree = { api = { node = { navigate = { sibling = {}, git = {}, diagnostics = {}, opened = {}, }, run = {}, open = {}, buffer = {}, } } }

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

function nvim_tree.api.node.buffer.delete() end

function nvim_tree.api.node.buffer.wipe() end

function nvim_tree.api.node.collapse() end

function nvim_tree.api.node.expand() end

function nvim_tree.api.node.navigate.diagnostics.next() end

function nvim_tree.api.node.navigate.diagnostics.next_recursive() end

function nvim_tree.api.node.navigate.diagnostics.prev() end

function nvim_tree.api.node.navigate.diagnostics.prev_recursive() end

function nvim_tree.api.node.navigate.git.next() end

function nvim_tree.api.node.navigate.git.next_recursive() end

function nvim_tree.api.node.navigate.git.next_skip_gitignored() end

function nvim_tree.api.node.navigate.git.prev() end

function nvim_tree.api.node.navigate.git.prev_recursive() end

function nvim_tree.api.node.navigate.git.prev_skip_gitignored() end

function nvim_tree.api.node.navigate.opened.next() end

function nvim_tree.api.node.navigate.opened.prev() end

function nvim_tree.api.node.navigate.parent() end

function nvim_tree.api.node.navigate.parent_close() end

function nvim_tree.api.node.navigate.sibling.first() end

function nvim_tree.api.node.navigate.sibling.last() end

function nvim_tree.api.node.navigate.sibling.next() end

function nvim_tree.api.node.navigate.sibling.prev() end

function nvim_tree.api.node.open.drop() end

function nvim_tree.api.node.open.edit() end

function nvim_tree.api.node.open.horizontal() end

function nvim_tree.api.node.open.horizontal_no_picker() end

function nvim_tree.api.node.open.no_window_picker() end

function nvim_tree.api.node.open.preview() end

function nvim_tree.api.node.open.preview_no_picker() end

function nvim_tree.api.node.open.replace_tree_buffer() end

function nvim_tree.api.node.open.tab() end

function nvim_tree.api.node.open.tab_drop() end

function nvim_tree.api.node.open.toggle_group_empty() end

function nvim_tree.api.node.open.vertical() end

function nvim_tree.api.node.open.vertical_no_picker() end

function nvim_tree.api.node.run.cmd() end

function nvim_tree.api.node.run.system() end

function nvim_tree.api.node.show_info_popup() end

require("nvim-tree.api").hydrate_node(nvim_tree.api.node)

return nvim_tree.api.node
