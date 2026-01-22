---@meta
local nvim_tree = { api = { node = { open = {}, } } }

---
---@class nvim_tree.api.node.open.Opts
---@inlinedoc
---
---Quits the tree when opening the file.
---(default: false)
---@field quit_on_open? boolean
---
---Keep focus in the tree when opening the file.
---(default: false)
---@field focus? boolean


---
---- file: open as per [nvim_tree.config.actions.open_file]
---- directory: expand or collapse
---- root: change directory up
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.Opts optional
function nvim_tree.api.node.open.edit(node, opts) end

---
---Open file in a new horizontal split.
---
---@param node? nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.open.Opts optional
function nvim_tree.api.node.open.horizontal(node, opts) end

---
---Open file in a new horizontal split without using the window picker.
---
---@param node? nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.open.Opts optional
function nvim_tree.api.node.open.horizontal_no_picker(node, opts) end

---
---Open file without using the window picker.
---
---@param node? nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.open.Opts optional
function nvim_tree.api.node.open.no_window_picker(node, opts) end

---
---Open file with ['bufhidden'] set to `delete`.
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.Opts optional
function nvim_tree.api.node.open.preview(node, opts) end

---
---Open file with ['bufhidden'] set to `delete` without using the window picker.
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.Opts optional
function nvim_tree.api.node.open.preview_no_picker(node, opts) end

---
---Open file in place: in the nvim-tree window.
---
---@param node? nvim_tree.api.Node file
function nvim_tree.api.node.open.replace_tree_buffer(node) end

---
---Open file in a new tab.
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.Opts optional
function nvim_tree.api.node.open.tab(node, opts) end

---
---Switch to tab containing window with selected file if it exists. Open file in new tab otherwise.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.open.tab_drop(node) end

---
---Toggle [nvim_tree.config.renderer] {group_empty} for a directory. Needs {group_empty} set.
---
---@param node? nvim_tree.api.Node directory
---@param opts? nvim_tree.api.node.open.Opts optional
function nvim_tree.api.node.open.toggle_group_empty(node, opts) end

---
---Open file in a new vertical split.
---
---@param node? nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.open.Opts optional
function nvim_tree.api.node.open.vertical(node, opts) end

---
---Open file in a new vertical split without using the window picker.
---
---@param node? nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.open.Opts optional
function nvim_tree.api.node.open.vertical_no_picker(node, opts) end

return nvim_tree.api.node.open
