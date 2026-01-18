---@meta
local nvim_tree = { api = { node = { navigate = { sibling = {}, git = {}, diagnostics = {}, opened = {}, }, run = {}, open = {}, buffer = {}, } } }

---@class ApiNodeDeleteWipeBufferOpts
---@field force boolean|nil default false

---@class NodeEditOpts
---@field quit_on_open boolean|nil default false
---@field focus boolean|nil default true

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

require("nvim-tree.api.impl").node(nvim_tree.api.node)

return nvim_tree.api.node
