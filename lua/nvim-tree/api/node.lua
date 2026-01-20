---@meta
local nvim_tree = { api = { node = { navigate = { sibling = {}, git = {}, diagnostics = {}, opened = {}, }, run = {}, open = {}, buffer = {}, } } }


---
---Deletes node's related buffer, if one exists. Executes [:bdelete] or [:bdelete]!
---
---@param node nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.buffer.delete.Opts
function nvim_tree.api.node.buffer.delete(node, opts) end

---@class nvim_tree.api.node.buffer.delete.Opts optional
---@inlinedoc
---
---Delete even if buffer is modified.
---(default: false)
---@field force? boolean

---
---Wipes node's related buffer, if one exists. Executes [:bwipe] or [:bwipe]!
---
---@param node? nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.buffer.wipe.Opts optional
function nvim_tree.api.node.buffer.wipe(node, opts) end

---@class nvim_tree.api.node.buffer.wipe.Opts
---@inlinedoc
---
---Wipe even if buffer is modified.
---(default: false)
---@field force? boolean

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
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.expand.Opts optional
function nvim_tree.api.node.expand(node, opts) end

---@class nvim_tree.api.node.expand.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.next(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.next_recursive(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.prev(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.prev_recursive(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.next(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.next_recursive(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.next_skip_gitignored(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.prev(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.prev_recursive(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.prev_skip_gitignored(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.opened.next(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.opened.prev(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.parent(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.parent_close(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.first(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.last(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.next(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.prev(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.open.drop(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.edit.Opts optional
function nvim_tree.api.node.open.edit(node, opts) end

---@class nvim_tree.api.node.open.edit.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.horizontal.Opts optional
function nvim_tree.api.node.open.horizontal(node, opts) end

---@class nvim_tree.api.node.open.horizontal.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.horizontal_no_picker.Opts optional
function nvim_tree.api.node.open.horizontal_no_picker(node, opts) end

---@class nvim_tree.api.node.open.horizontal_no_picker.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.no_window_picker.Opts optional
function nvim_tree.api.node.open.no_window_picker(node, opts) end

---@class nvim_tree.api.node.open.no_window_picker.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.preview.Opts optional
function nvim_tree.api.node.open.preview(node, opts) end

---@class nvim_tree.api.node.open.preview.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.preview_no_picker.Opts optional
function nvim_tree.api.node.open.preview_no_picker(node, opts) end

---@class nvim_tree.api.node.open.preview_no_picker.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.open.replace_tree_buffer(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.tab.Opts optional
function nvim_tree.api.node.open.tab(node, opts) end

---@class nvim_tree.api.node.open.tab.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.open.tab_drop(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.toggle_group_empty.Opts optional
function nvim_tree.api.node.open.toggle_group_empty(node, opts) end

---@class nvim_tree.api.node.open.toggle_group_empty.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.vertical.Opts optional
function nvim_tree.api.node.open.vertical(node, opts) end

---@class nvim_tree.api.node.open.vertical.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.open.vertical_no_picker.Opts optional
function nvim_tree.api.node.open.vertical_no_picker(node, opts) end

---@class nvim_tree.api.node.open.vertical_no_picker.Opts
---@inlinedoc
---
---
---(default: false)
---@field foo? boolean

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.run.cmd(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.run.system(node) end

---
---
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.show_info_popup(node) end





-- node.open.edit({node}, {opts})                        *nvim-tree-api.node.open.edit()*
--     File:   open as per |nvim-tree.actions.open_file|
--     Folder: expand or collapse
--     Root:   change directory up
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {quit_on_open} (boolean) quits the tree when opening the file
--       • {focus} (boolean) keep focus in the tree when opening the file
--
--                                *nvim-tree-api.node.open.replace_tree_buffer()*
-- node.open.replace_tree_buffer({node})
--     |nvim-tree-api.node.edit()|, file will be opened in place: in the
--     nvim-tree window.
--
--                                   *nvim-tree-api.node.open.no_window_picker()*
-- node.open.no_window_picker({node}, {opts})
--     |nvim-tree-api.node.edit()|, window picker will never be used as per
--     |nvim-tree.actions.open_file.window_picker.enable| `false`
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {quit_on_open} (boolean) quits the tree when opening the file
--       • {focus} (boolean) keep focus in the tree when opening the file
--
-- node.open.vertical({node}, {opts})                *nvim-tree-api.node.open.vertical()*
--     |nvim-tree-api.node.edit()|, file will be opened in a new vertical split.
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {quit_on_open} (boolean) quits the tree when opening the file
--       • {focus} (boolean) keep focus in the tree when opening the file
--
--                                 *nvim-tree-api.node.open.vertical_no_picker()*
-- node.open.vertical_no_picker({node}, {opts})
--     |nvim-tree-api.node.vertical()|, window picker will never be used as per
--     |nvim-tree.actions.open_file.window_picker.enable| `false`
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {quit_on_open} (boolean) quits the tree when opening the file
--       • {focus} (boolean) keep focus in the tree when opening the file
--
-- node.open.horizontal({node}, {opts})            *nvim-tree-api.node.open.horizontal()*
--     |nvim-tree-api.node.edit()|, file will be opened in a new horizontal split.
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {quit_on_open} (boolean) quits the tree when opening the file
--       • {focus} (boolean) keep focus in the tree when opening the file
--
--                               *nvim-tree-api.node.open.horizontal_no_picker()*
-- node.open.horizontal_no_picker({node}, {opts})
--     |nvim-tree-api.node.horizontal()|, window picker will never be used as per
--     |nvim-tree.actions.open_file.window_picker.enable| `false`
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {quit_on_open} (boolean) quits the tree when opening the file
--       • {focus} (boolean) keep focus in the tree when opening the file
--
--                                 *nvim-tree-api.node.open.toggle_group_empty()*
-- node.open.toggle_group_empty({node}, {opts})
--     Toggle |nvim-tree.renderer.group_empty| for a specific folder.
--     Does nothing on files.
--     Needs |nvim-tree.renderer.group_empty| set.
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {quit_on_open} (boolean) quits the tree when opening the file
--       • {focus} (boolean) keep focus in the tree when opening the file
--
-- node.open.drop({node})                        *nvim-tree-api.node.open.drop()*
--     Switch to window with selected file if it exists.
--     Open file otherwise.
--     See: `:h :drop`.
--
--     File:   open file using `:drop`
--     Folder: expand or collapse
--     Root:   change directory up
--
-- node.open.tab({node}, {opts})                          *nvim-tree-api.node.open.tab()*
--     |nvim-tree-api.node.edit()|, file will be opened in a new tab.
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {quit_on_open} (boolean) quits the tree when opening the file
--       • {focus} (boolean) keep focus in the tree when opening the file
--
--                                           *nvim-tree-api.node.open.tab_drop()*
-- node.open.tab_drop({node})
--     Switch to tab containing window with selected file if it exists.
--     Open file in new tab otherwise.
--
--     File:   open file using `tab :drop`
--     Folder: expand or collapse
--     Root:   change directory up
--
-- node.open.preview({node}, {opts})                  *nvim-tree-api.node.open.preview()*
--     |nvim-tree-api.node.edit()|, file buffer will have |bufhidden| set to `delete`.
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {quit_on_open} (boolean) quits the tree when opening the file
--       • {focus} (boolean) keep focus in the tree when opening the file
--
--                                  *nvim-tree-api.node.open.preview_no_picker()*
-- node.open.preview_no_picker({node}, {opts})
--     |nvim-tree-api.node.edit()|, file buffer will have |bufhidden| set to `delete`.
--     window picker will never be used as per
--     |nvim-tree.actions.open_file.window_picker.enable| `false`
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {quit_on_open} (boolean) quits the tree when opening the file
--       • {focus} (boolean) keep focus in the tree when opening the file
--
-- node.navigate.git.next({node})        *nvim-tree-api.node.navigate.git.next()*
--     Navigate to the next item showing git status.
--
--                             *nvim-tree-api.node.navigate.git.next_recursive()*
-- node.navigate.git.next_recursive({node})
--     Alternative to |nvim-tree-api.node.navigate.git.next()| that navigates to
--     the next file showing git status, recursively.
--     Needs |nvim-tree.git.show_on_dirs| set.
--
--                       *nvim-tree-api.node.navigate.git.next_skip_gitignored()*
-- node.navigate.git.next_skip_gitignored({node})
--     Same as |node.navigate.git.next()|, but skips gitignored files.
--
-- node.navigate.git.prev({node})        *nvim-tree-api.node.navigate.git.prev()*
--     Navigate to the previous item showing git status.
--
--                       *nvim-tree-api.node.navigate.git.prev_recursive()*
-- node.navigate.git.prev_recursive({node})
--     Alternative to |nvim-tree-api.node.navigate.git.prev()| that navigates to
--     the previous file showing git status, recursively.
--     Needs |nvim-tree.git.show_on_dirs| set.
--
--                       *nvim-tree-api.node.navigate.git.prev_skip_gitignored()*
-- node.navigate.git.prev_skip_gitignored({node})
--     Same as |node.navigate.git.prev()|, but skips gitignored files.
--
--                               *nvim-tree-api.node.navigate.diagnostics.next()*
-- node.navigate.diagnostics.next({node})
--     Navigate to the next item showing diagnostic status.
--
--                     *nvim-tree-api.node.navigate.diagnostics.next_recursive()*
-- node.navigate.diagnostics.next_recursive({node})
--     Alternative to |nvim-tree-api.node.navigate.diagnostics.next()| that
--     navigates to the next file showing diagnostic status, recursively.
--     Needs |nvim-tree.diagnostics.show_on_dirs| set.
--
--                               *nvim-tree-api.node.navigate.diagnostics.prev()*
-- node.navigate.diagnostics.prev({node})
--     Navigate to the next item showing diagnostic status.
--
--                     *nvim-tree-api.node.navigate.diagnostics.prev_recursive()*
-- node.navigate.diagnostics.prev_recursive({node})
--     Alternative to |nvim-tree-api.node.navigate.diagnostics.prev()| that
--     navigates to the previous file showing diagnostic status, recursively.
--     Needs |nvim-tree.diagnostics.show_on_dirs| set.
--
--                                    *nvim-tree-api.node.navigate.opened.next()*
-- node.navigate.opened.next({node})
--     Navigate to the next |bufloaded()| item.
--     See |nvim-tree.renderer.highlight_opened_files|
--
--                                    *nvim-tree-api.node.navigate.opened.prev()*
-- node.navigate.opened.prev({node})
--     Navigate to the previous |bufloaded()| item.
--     See |nvim-tree.renderer.highlight_opened_files|
--
--                                   *nvim-tree-api.node.navigate.sibling.next()*
-- node.navigate.sibling.next({node})
--     Navigate to the next node in the current node's folder, wraps.
--
--                                   *nvim-tree-api.node.navigate.sibling.prev()*
-- node.navigate.sibling.prev({node})
--     Navigate to the previous node in the current node's folder, wraps.
--
--                                  *nvim-tree-api.node.navigate.sibling.first()*
-- node.navigate.sibling.first({node})
--     Navigate to the first node in the current node's folder.
--
--                                   *nvim-tree-api.node.navigate.sibling.last()*
-- node.navigate.sibling.last({node})
--     Navigate to the last node in the current node's folder.
--
--                                         *nvim-tree-api.node.navigate.parent()*
-- node.navigate.parent({node})
--     Navigate to the parent folder of the current node.
--
--                                   *nvim-tree-api.node.navigate.parent_close()*
-- node.navigate.parent_close({node})
--     |api.node.navigate.parent()|, closing that folder.
--
-- node.show_info_popup({node})            *nvim-tree-api.node.show_info_popup()*
--     Open a popup window showing: fullpath, size, accessed, modified, created.
--
-- node.run.cmd({node})                            *nvim-tree-api.node.run.cmd()*
--     Enter |cmdline| with the full path of the node and the cursor at the start
--     of the line.
--
-- node.run.system({node})                      *nvim-tree-api.node.run.system()*
--     Execute |nvim-tree.system_open|
--
-- node.buffer.delete({node}, {opts})        *nvim-tree-api.node.buffer.delete()*
--     Deletes node's related buffer, if one exists.
--     Executes |:bdelete| or |:bdelete|!
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {force} (boolean) delete even if buffer is modified, default false
--
-- node.buffer.wipe({node}, {opts})            *nvim-tree-api.node.buffer.wipe()*
--     Wipes node's related buffer, if one exists.
--     Executes |:bwipe| or |:bwipe|!
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {force} (boolean) wipe even if buffer is modified, default false
--
-- node.expand({node}, {opts})                      *nvim-tree-api.node.expand()*
--     Recursively expand all nodes under a directory or a file's parent
--     directory.
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (ApiTreeExpandOpts) optional parameters
--
--     Options: ~
--       • {expand_until} ((fun(expansion_count: integer, node: Node?): boolean)?)
--             Return true if {node} should be expanded.
--             {expansion_count} is the total number of folders expanded.
--
-- node.collapse({node}, {opts})                  *nvim-tree-api.node.collapse()*
--     Collapse the tree under a directory or a file's parent directory.
--
--     Parameters: ~
--       • {node} (Node|nil) file or folder
--       • {opts} (table) optional parameters
--
--     Options: ~
--       • {keep_buffers} (boolean) do not collapse nodes with open buffers.

require("nvim-tree.api.impl").node(nvim_tree.api.node)

return nvim_tree.api.node
