---@meta
local nvim_tree = { api = { node = { navigate = { sibling = {}, git = {}, diagnostics = {}, opened = {}, }, run = {}, open = {}, buffer = {}, } } }

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
---@class nvim_tree.api.node.buffer.RemoveOpts
---@inlinedoc
---
---Proceed even if the buffer is modified.
---(default: false)
---@field force? boolean


---
---Deletes node's related buffer, if one exists. Executes [:bdelete] or [:bdelete]!
---
---@param node nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.buffer.RemoveOpts
function nvim_tree.api.node.buffer.delete(node, opts) end

---
---Wipes node's related buffer, if one exists. Executes [:bwipe] or [:bwipe]!
---
---@param node? nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.buffer.RemoveOpts optional
function nvim_tree.api.node.buffer.wipe(node, opts) end

---
---Collapse the tree under a directory or a file's parent directory.
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.collapse.Opts optional
function nvim_tree.api.node.collapse(node, opts) end

---@class nvim_tree.api.node.collapse.Opts
---@inlinedoc
---
---Do not collapse nodes with open buffers.
---(default: false)
---@field keep_buffers? boolean

---
---Recursively expand all nodes under a directory or a file's parent directory.
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.expand.Opts optional
function nvim_tree.api.node.expand(node, opts) end

---@class nvim_tree.api.node.expand.Opts
---@inlinedoc
---
---Return `true` if `node` should be expanded. `expansion_count` is the total number of folders expanded.
---@field expand_until? fun(expansion_count: integer, node: Node): boolean

---
---Navigate to the next item showing diagnostic status.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.next(node) end

---
---Navigate to the next item showing diagnostic status, recursively. Needs [nvim_tree.config.diagnostics] {show_on_dirs}
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.next_recursive(node) end

---
---Navigate to the previous item showing diagnostic status.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.prev(node) end

---
---Navigate to the previous item showing diagnostic status, recursively. Needs [nvim_tree.config.diagnostics] {show_on_dirs}
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.prev_recursive(node) end

---
---Navigate to the next item showing git status.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.next(node) end

---
---Navigate to the next item showing git status, recursively. Needs [nvim_tree.config.git] {show_on_dirs}
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.next_recursive(node) end

---
---Navigate to the next item showing git status, skipping `.gitignore`
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.next_skip_gitignored(node) end

---
---Navigate to the previous item showing git status.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.prev(node) end

---
---Navigate to the previous item showing git status, recursively. Needs [nvim_tree.config.git] {show_on_dirs}
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.prev_recursive(node) end

---
---Navigate to the previous item showing git status, skipping `.gitignore`
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.prev_skip_gitignored(node) end

---
---Navigate to the next [bufloaded()] file.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.opened.next(node) end

---
---Navigate to the previous [bufloaded()] file.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.opened.prev(node) end

---
---Navigate to the parent directory of the node.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.parent(node) end

---
---Navigate to the parent directory of the node, closing it.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.parent_close(node) end

---
---Navigate to the first node in the current node's folder.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.first(node) end

---
---Navigate to the last node in the current node's folder.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.last(node) end

---
---Navigate to the next node in the current node's folder, wraps.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.next(node) end

---
---Navigate to the previous node in the current node's folder, wraps.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.prev(node) end

---
---Switch to window with selected file if it exists, open file otherwise.
---- file: open file using [:drop]
---- directory: expand or collapse
---- root: change directory up
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.open.drop(node) end

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

---
---Enter [cmdline] with the full path of the node and the cursor at the start of the line.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.run.cmd(node) end

---
---Execute [nvim_tree.config.system_open].
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.run.system(node) end

---
---Open a popup window showing: fullpath, size, accessed, modified, created.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.show_info_popup(node) end

return nvim_tree.api.node
