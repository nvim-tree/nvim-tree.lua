---Hydrates all API functions with concrete implementations.
---All "nvim-tree setup not called" error functions from pre.lua will be replaced.
---
---Call this after nvim-tree setup
---
---All requires must be done lazily so that requiring api post setup is cheap.

local legacy = require("nvim-tree.legacy")

local M = {}

--- convenience wrappers for lazy module requires
local function actions() return require("nvim-tree.actions") end
local function core() return require("nvim-tree.core") end
local function config() return require("nvim-tree.config") end
local function help() return require("nvim-tree.help") end
local function keymap() return require("nvim-tree.keymap") end
local function utils() return require("nvim-tree.utils") end
local function view() return require("nvim-tree.view") end

-- TODO 3255 wrap* must be able to take a function. May be best to have that function accept (node, ...)

---Invoke a method on the singleton explorer.
---Print error when setup not called.
---@param explorer_method string explorer method name
---@return fun(...): any
local function wrap_explorer(explorer_method)
  return function(...)
    local explorer = core().get_explorer()
    if explorer then
      return explorer[explorer_method](explorer, ...)
    end
  end
end

---Inject the node as the first argument if present otherwise do nothing.
---@param fn fun(node: Node, ...): any
---@return fun(node: Node?, ...): any
local function wrap_node(fn)
  return function(node, ...)
    node = node or wrap_explorer("get_node_at_cursor")()
    if node then
      return fn(node, ...)
    end
  end
end

---Inject the node or nil as the first argument if absent.
---@param fn fun(node: Node?, ...): any
---@return fun(node: Node?, ...): any
local function wrap_node_or_nil(fn)
  return function(node, ...)
    node = node or wrap_explorer("get_node_at_cursor")()
    return fn(node, ...)
  end
end

---Invoke a member's method on the singleton explorer.
---Print error when setup not called.
---@param explorer_member string explorer member name
---@param member_method string method name to invoke on member
---@param ... any passed to method
---@return fun(...): any
local function wrap_explorer_member_args(explorer_member, member_method, ...)
  local method_args = ...
  return function(...)
    local explorer = core().get_explorer()
    if explorer then
      return explorer[explorer_member][member_method](explorer[explorer_member], method_args, ...)
    end
  end
end

---Invoke a member's method on the singleton explorer.
---Print error when setup not called.
---@param explorer_member string explorer member name
---@param member_method string method name to invoke on member
---@return fun(...): any
local function wrap_explorer_member(explorer_member, member_method)
  return function(...)
    local explorer = core().get_explorer()
    if explorer then
      return explorer[explorer_member][member_method](explorer[explorer_member], ...)
    end
  end
end

local function hydrate_config(api)
  api.config.global = function() return config().g_clone() end
  api.config.user   = function() return config().u_clone() end
end

local function hydrate_filter(api)
  api.filter.custom.toggle      = wrap_explorer_member_args("filters", "toggle", "custom")
  api.filter.dotfiles.toggle    = wrap_explorer_member_args("filters", "toggle", "dotfiles")
  api.filter.git.clean.toggle   = wrap_explorer_member_args("filters", "toggle", "git_clean")
  api.filter.git.ignored.toggle = wrap_explorer_member_args("filters", "toggle", "git_ignored")
  api.filter.live.clear         = wrap_explorer_member("live_filter", "clear_filter")
  api.filter.live.start         = wrap_explorer_member("live_filter", "start_filtering")
  api.filter.no_bookmark.toggle = wrap_explorer_member_args("filters", "toggle", "no_bookmark")
  api.filter.no_buffer.toggle   = wrap_explorer_member_args("filters", "toggle", "no_buffer")
  api.filter.toggle             = wrap_explorer_member("filters", "toggle")
end

local function hydrate_fs(api)
  api.fs.clear_clipboard    = wrap_explorer_member("clipboard", "clear_clipboard")
  api.fs.copy.absolute_path = wrap_node(wrap_explorer_member("clipboard", "copy_absolute_path"))
  api.fs.copy.basename      = wrap_node(wrap_explorer_member("clipboard", "copy_basename"))
  api.fs.copy.filename      = wrap_node(wrap_explorer_member("clipboard", "copy_filename"))
  api.fs.copy.node          = wrap_node(wrap_explorer_member("clipboard", "copy"))
  api.fs.copy.relative_path = wrap_node(wrap_explorer_member("clipboard", "copy_path"))
  api.fs.create             = wrap_node_or_nil(actions().fs.create_file.fn)
  api.fs.cut                = wrap_node(wrap_explorer_member("clipboard", "cut"))
  api.fs.paste              = wrap_node(wrap_explorer_member("clipboard", "paste"))
  api.fs.print_clipboard    = wrap_explorer_member("clipboard", "print_clipboard")
  api.fs.remove             = wrap_node(actions().fs.remove_file.fn)
  api.fs.rename             = wrap_node(actions().fs.rename_file.rename_node)
  api.fs.rename_basename    = wrap_node(actions().fs.rename_file.rename_basename)
  api.fs.rename_full        = wrap_node(actions().fs.rename_file.rename_full)
  api.fs.rename_node        = wrap_node(actions().fs.rename_file.rename_node)
  api.fs.rename_sub         = wrap_node(actions().fs.rename_file.rename_sub)
  api.fs.trash              = wrap_node(actions().fs.trash.fn)
end

local function hydrate_map(api)
  api.map.keymap.current = function() return keymap().get_keymap() end
end

local function hydrate_marks(api)
  api.marks.bulk.delete     = wrap_explorer_member("marks", "bulk_delete")
  api.marks.bulk.move       = wrap_explorer_member("marks", "bulk_move")
  api.marks.bulk.trash      = wrap_explorer_member("marks", "bulk_trash")
  api.marks.clear           = wrap_explorer_member("marks", "clear")
  api.marks.get             = wrap_node(wrap_explorer_member("marks", "get"))
  api.marks.list            = wrap_explorer_member("marks", "list")
  api.marks.navigate.next   = wrap_explorer_member("marks", "navigate_next")
  api.marks.navigate.prev   = wrap_explorer_member("marks", "navigate_prev")
  api.marks.navigate.select = wrap_explorer_member("marks", "navigate_select")
  api.marks.toggle          = wrap_node(wrap_explorer_member("marks", "toggle"))
end

local function hydrate_node(api)
  api.node.buffer.delete                       = wrap_node(function(node, opts) actions().node.buffer.delete(node, opts) end)
  api.node.buffer.wipe                         = wrap_node(function(node, opts) actions().node.buffer.wipe(node, opts) end)
  api.node.collapse                            = wrap_node(actions().tree.collapse.node)
  api.node.expand                              = wrap_node(wrap_explorer("expand_node"))
  api.node.navigate.diagnostics.next           = function() return actions().moves.item.diagnostics_next() end
  api.node.navigate.diagnostics.next_recursive = function() return actions().moves.item.diagnostics_next_recursive() end
  api.node.navigate.diagnostics.prev           = function() return actions().moves.item.diagnostics_prev() end
  api.node.navigate.diagnostics.prev_recursive = function() return actions().moves.item.diagnostics_prev_recursive() end
  api.node.navigate.git.next                   = function() return actions().moves.item.git_next() end
  api.node.navigate.git.next_recursive         = function() return actions().moves.item.git_next_recursive() end
  api.node.navigate.git.next_skip_gitignored   = function() return actions().moves.item.git_next_skip_gitignored() end
  api.node.navigate.git.prev                   = function() return actions().moves.item.git_prev() end
  api.node.navigate.git.prev_recursive         = function() return actions().moves.item.git_prev_recursive() end
  api.node.navigate.git.prev_skip_gitignored   = function() return actions().moves.item.git_prev_skip_gitignored() end
  api.node.navigate.opened.next                = function() return actions().moves.item.opened_next() end
  api.node.navigate.opened.prev                = function() return actions().moves.item.opened_prev() end
  api.node.navigate.parent                     = wrap_node(actions().moves.parent.move)
  api.node.navigate.parent_close               = wrap_node(actions().moves.parent.move_close)
  api.node.navigate.sibling.first              = wrap_node(actions().moves.sibling.first)
  api.node.navigate.sibling.last               = wrap_node(actions().moves.sibling.last)
  api.node.navigate.sibling.next               = wrap_node(actions().moves.sibling.next)
  api.node.navigate.sibling.prev               = wrap_node(actions().moves.sibling.prev)
  api.node.open.drop                           = wrap_node(actions().node.open_file.drop)
  api.node.open.edit                           = wrap_node(actions().node.open_file.edit)
  api.node.open.horizontal                     = wrap_node(actions().node.open_file.horizontal)
  api.node.open.horizontal_no_picker           = wrap_node(actions().node.open_file.horizontal_no_picker)
  api.node.open.no_window_picker               = wrap_node(actions().node.open_file.no_window_picker)
  api.node.open.preview                        = wrap_node(actions().node.open_file.preview)
  api.node.open.preview_no_picker              = wrap_node(actions().node.open_file.preview_no_picker)
  api.node.open.replace_tree_buffer            = wrap_node(actions().node.open_file.replace_tree_buffer)
  api.node.open.tab                            = wrap_node(actions().node.open_file.tab)
  api.node.open.tab_drop                       = wrap_node(actions().node.open_file.tab_drop)
  api.node.open.toggle_group_empty             = wrap_node(actions().node.open_file.toggle_group_empty)
  api.node.open.vertical                       = wrap_node(actions().node.open_file.vertical)
  api.node.open.vertical_no_picker             = wrap_node(actions().node.open_file.vertical_no_picker)
  api.node.run.cmd                             = wrap_node(actions().node.run_command.run_file_command)
  api.node.run.system                          = wrap_node(actions().node.system_open.fn)
  api.node.show_info_popup                     = wrap_node(actions().node.file_popup.toggle_file_info)
end

local function hydrate_tree(api)
  api.tree.change_root           = function() return actions().tree.change_dir.fn() end
  api.tree.change_root_to_node   = wrap_node(wrap_explorer("change_dir_to_node"))
  api.tree.change_root_to_parent = wrap_node(wrap_explorer("dir_up"))
  api.tree.close                 = function() return view().close() end
  api.tree.close_in_all_tabs     = function() return view().close_all_tabs() end
  api.tree.close_in_this_tab     = function() return view().close_this_tab_only() end
  api.tree.collapse_all          = function() return actions().tree.collapse.all() end
  api.tree.expand_all            = wrap_node(wrap_explorer("expand_all"))
  api.tree.find_file             = function() return actions().tree.find_file.fn() end
  api.tree.focus                 = api.tree.open
  api.tree.get_node_under_cursor = wrap_explorer("get_node_at_cursor")
  api.tree.get_nodes             = wrap_explorer("get_nodes")
  api.tree.is_tree_buf           = function() return utils().is_nvim_tree_buf() end
  api.tree.is_visible            = function() return view().is_visible() end
  api.tree.open                  = function() return actions().tree.open.fn() end
  api.tree.reload                = wrap_explorer("reload_explorer")
  api.tree.reload_git            = wrap_explorer("reload_git")
  api.tree.resize                = function() return actions().tree.resize.fn() end
  api.tree.search_node           = function() return actions().finders.search_node.fn() end
  api.tree.toggle                = function() return actions().tree.toggle.fn() end
  api.tree.toggle_help           = function() return help().toggle() end
  api.tree.winid                 = function() return view().winid() end
end

---Re-Hydrate api functions and classes post-setup
---@param api table not properly typed to prevent LSP from referencing implementations
function M.hydrate(api)
  -- hydration has been split into functions for readability and formatting
  hydrate_config(api)
  hydrate_filter(api)
  hydrate_fs(api)
  hydrate_map(api)
  hydrate_marks(api)
  hydrate_node(api)
  hydrate_tree(api)

  -- (Re)hydrate any legacy by mapping to concrete set above
  legacy.map_api(api)
end

return M
