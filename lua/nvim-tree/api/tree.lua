---@meta
local nvim_tree = { api = { tree = {} } }



---@class nvim_tree.api.tree.open.Opts
---@inlinedoc
---
---Root directory for the tree
---@field path? string
---
---Open the tree in the current window
---(default: false)
---@field current_window? boolean
---
---Open the tree in the specified [winid], overrides {current_window}
---@field winid? number
---
---Find the current buffer.
---(default: false)
---@field find_file? boolean
---
---Update root following {find_file}, see [nvim_tree.Config.UpdateFocusedFile] {update_root}
---(default: false)
---@field update_root? boolean

---Open the tree, focusing it if already open.
---
---@param opts? nvim_tree.api.tree.open.Opts optional
function nvim_tree.api.tree.open(opts) end



---@class nvim_tree.api.tree.toggle.Opts
---@inlinedoc
---
---Root directory for the tree
---@field path? string
---
---Open the tree in the current window
---(default: false)
---@field current_window? boolean
---
---Open the tree in the specified [winid], overrides {current_window}
---@field winid? number
---
---Find the current buffer.
---(default: false)
---@field find_file? boolean
---
---Focus the tree when opening.
---(default: true)
---@field focus? boolean

---Open or close the tree.
---
---@param opts? nvim_tree.api.tree.toggle.Opts optional
function nvim_tree.api.tree.toggle(opts) end



---Close the tree, affecting all tabs as per [nvim_tree.Config.Tab.Sync] {close}
---
function nvim_tree.api.tree.close() end


---Close the tree in this tab only.
---
function nvim_tree.api.tree.close_in_this_tab() end


---Close the tree in all tabs.
---
function nvim_tree.api.tree.close_in_all_tabs() end



---Focus the tree, opening it if necessary. Retained for compatibility, use [nvim_tree.api.tree.open()] with no arguments instead.
---
function nvim_tree.api.tree.focus() end


---Refresh the tree. Does nothing if closed.
---
function nvim_tree.api.tree.reload() end



---@class nvim_tree.api.tree.resize.Opts
---@inlinedoc
---
---New [nvim_tree.Config.View] {width} value.
---@field width nvim_tree.Config.View.WidthSpec|nvim_tree.Config.View.Width
---
---Set the width.
---@field absolute number
---
---Increase or decrease the width.
---@field relative number

---Resize the tree, persisting the new size. Resets to [nvim_tree.Config.View] {width} when no {opts} provided.
---
---Only one option is supported, priority order: {width}, {absolute}, {relative}.
---
---{absolute} and {relative} do nothing when [nvim_tree.Config.View] {width} is a function.
---@param opts? nvim_tree.api.tree.resize.Opts optional
function nvim_tree.api.tree.resize(opts) end



---Change the tree's root to a path.
---
---@param path? string absolute or relative path.
function nvim_tree.api.tree.change_root(path) end



---Change the tree's root to a folder node or the parent of a file node.
---
---@param node nvim_tree.api.Node directory or file
function nvim_tree.api.tree.change_root_to_node(node) end


---Change the tree's root to the parent of a node.
---
---@param node nvim_tree.api.Node directory or file
function nvim_tree.api.tree.change_root_to_parent(node) end


---Retrieve the currently focused node.
---
---@return nvim_tree.api.Node? nil if tree is not visible.
function nvim_tree.api.tree.get_node_under_cursor() end


---Retrieve a hierarchical list of all the nodes.
---
---@return nvim_tree.api.Node[]
function nvim_tree.api.tree.get_nodes() end



---@class nvim_tree.api.tree.find_file.Opts
---@inlinedoc
---
---Absolute/relative path OR [bufnr()] to find.
---@field buf? string|number
---
---Open the tree if necessary.
---(default: false)
---@field open? boolean
---
---Requires {open}: open in the current window.
---(default: false)
---@field current_window? boolean
---
---Open the tree in the specified [winid], overrides {current_window}
---@field winid? number
---
---Update root after find, see [nvim_tree.Config.UpdateFocusedFile] {update_root}
---(default: false)
---@field update_root? boolean
---
---Focus the tree window.
---(default: false)
---@field focus? boolean

---Find and focus a file or folder in the tree. Finds current buffer unless otherwise specified.
---
---@param opts? nvim_tree.api.tree.find_file.Opts optional
function nvim_tree.api.tree.find_file(opts) end



---Open the search dialogue.
---
function nvim_tree.api.tree.search_node() end



---@class nvim_tree.api.tree.collapse.Opts
---@inlinedoc
---
---Do not collapse nodes with open buffers.
---(default: false)
---@field keep_buffers? boolean

---Collapse the tree.
---
---@param opts? nvim_tree.api.tree.collapse.Opts optional
function nvim_tree.api.tree.collapse_all(opts) end



--- TODO #3088 move expand/collapse into api.node

---@class nvim_tree.api.tree.expand.Opts
---@inlinedoc
---
---Return `true` if `node` should be expanded. `expansion_count` is the total number of folders expanded.
---@field expand_until? fun(expansion_count: integer, node: Node): boolean

---Recursively expand all nodes under the tree root or specified folder.
---@param node? nvim_tree.api.Node directory
---@param opts? nvim_tree.api.tree.expand.Opts optional
function nvim_tree.api.tree.expand_all(node, opts) end



---Toggle [nvim_tree.Config.Filters] {enable} all filters.
function nvim_tree.api.tree.toggle_enable_filters() end



---Toggle [nvim_tree.Config.Filters] {git_ignored} filter.
function nvim_tree.api.tree.toggle_gitignore_filter() end



---Toggle [nvim_tree.Config.Filters] {dotfiles} filter.
function nvim_tree.api.tree.toggle_hidden_filter() end



---Toggle [nvim_tree.Config.Filters] {git_clean} filter.
function nvim_tree.api.tree.toggle_git_clean_filter() end



---Toggle [nvim_tree.Config.Filters] {no_buffer} filter.
function nvim_tree.api.tree.toggle_no_buffer_filter() end



---Toggle [nvim_tree.Config.Filters] {no_bookmark} filter.
function nvim_tree.api.tree.toggle_no_bookmark_filter() end



---Toggle [nvim_tree.Config.Filters] {custom} filter.
function nvim_tree.api.tree.toggle_custom_filter() end




---Toggle help view.
function nvim_tree.api.tree.toggle_help() end



---Checks if a buffer is an nvim-tree.
---
---@param bufnr? number 0 or nil for current buffer.
---@return boolean
function nvim_tree.api.tree.is_tree_buf(bufnr) end



---@class nvim_tree.api.tree.is_visible.Opts
---@inlinedoc
---
--- [tab-ID] 0 or nil for current.
---@field tabpage? integer
---
---Visible on any tab.
---(default: false)
---@field any_tabpage? boolean

---Checks if nvim-tree is visible on the current, specified or any tab.
---
---@param opts? nvim_tree.api.tree.is_visible.Opts optional
---@return boolean
function nvim_tree.api.tree.is_visible(opts) end



---@class nvim_tree.api.tree.winid.Opts
---@inlinedoc
---
---[tab-ID] 0 or nil for current.
---@field tabpage? integer

---Retrieve the winid of the open tree.
---
---@param opts? nvim_tree.api.tree.winid.Opts optional
---@return integer? [winid], nil if tree is not visible.
function nvim_tree.api.tree.winid(opts) end



require("nvim-tree.api").hydrate_tree(nvim_tree.api.tree)

return nvim_tree.api.tree
