---Hydrates all API functions with concrete implementations.
---All "nvim-tree setup not called" error functions from pre.lua will be replaced.
---
---Call this after nvim-tree setup
---
---This is expensive as there are many cascading requires and is avoided
---until after setup has been called, so that the user may require API cheaply.

local legacy = require("nvim-tree.legacy")

local actions = require("nvim-tree.actions")
local config = require("nvim-tree.config")
local help = require("nvim-tree.help")
local keymap = require("nvim-tree.keymap")
local utils = require("nvim-tree.utils")
local view = require("nvim-tree.view")

local M = {}

---Invoke a method on the singleton explorer.
---Print error when setup not called.
---@param explorer_method string explorer method name
---@return fun(...): any
local function wrap_explorer(explorer_method)
  return function(...)
    local explorer = require("nvim-tree.core").get_explorer()
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
    local explorer = require("nvim-tree.core").get_explorer()
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
    local explorer = require("nvim-tree.core").get_explorer()
    if explorer then
      return explorer[explorer_member][member_method](explorer[explorer_member], ...)
    end
  end
end

---Re-Hydrate api functions and classes post-setup
---@param api table not properly typed to prevent LSP from referencing implementations
function M.hydrate(api)
  api.tree.open = actions.tree.open.fn
  api.tree.focus = api.tree.open

  api.tree.toggle = actions.tree.toggle.fn
  api.tree.close = view.close
  api.tree.close_in_this_tab = view.close_this_tab_only
  api.tree.close_in_all_tabs = view.close_all_tabs
  api.tree.reload = wrap_explorer("reload_explorer")

  api.tree.resize = actions.tree.resize.fn

  api.tree.change_root = actions.tree.change_dir.fn

  api.tree.change_root_to_node = wrap_node(wrap_explorer("change_dir_to_node"))
  api.tree.change_root_to_parent = wrap_node(wrap_explorer("dir_up"))
  api.tree.get_node_under_cursor = wrap_explorer("get_node_at_cursor")
  api.tree.get_nodes = wrap_explorer("get_nodes")

  api.tree.find_file = actions.tree.find_file.fn
  api.tree.search_node = actions.finders.search_node.fn

  api.tree.collapse_all = actions.tree.collapse.all

  api.tree.expand_all = wrap_node(wrap_explorer("expand_all"))
  api.tree.toggle_help = help.toggle
  api.tree.is_tree_buf = utils.is_nvim_tree_buf

  api.tree.is_visible = view.is_visible

  api.tree.winid = view.winid

  api.fs.create = wrap_node_or_nil(actions.fs.create_file.fn)
  api.fs.remove = wrap_node(actions.fs.remove_file.fn)
  api.fs.trash = wrap_node(actions.fs.trash.fn)
  api.fs.rename_node = wrap_node(actions.fs.rename_file.rename_node)
  api.fs.rename = wrap_node(actions.fs.rename_file.rename_node)
  api.fs.rename_sub = wrap_node(actions.fs.rename_file.rename_sub)
  api.fs.rename_basename = wrap_node(actions.fs.rename_file.rename_basename)
  api.fs.rename_full = wrap_node(actions.fs.rename_file.rename_full)
  api.fs.cut = wrap_node(wrap_explorer_member("clipboard", "cut"))
  api.fs.paste = wrap_node(wrap_explorer_member("clipboard", "paste"))
  api.fs.clear_clipboard = wrap_explorer_member("clipboard", "clear_clipboard")
  api.fs.print_clipboard = wrap_explorer_member("clipboard", "print_clipboard")
  api.fs.copy.node = wrap_node(wrap_explorer_member("clipboard", "copy"))
  api.fs.copy.absolute_path = wrap_node(wrap_explorer_member("clipboard", "copy_absolute_path"))
  api.fs.copy.filename = wrap_node(wrap_explorer_member("clipboard", "copy_filename"))
  api.fs.copy.basename = wrap_node(wrap_explorer_member("clipboard", "copy_basename"))
  api.fs.copy.relative_path = wrap_node(wrap_explorer_member("clipboard", "copy_path"))

  api.node.open.edit = wrap_node(actions.node.open_file.edit)
  api.node.open.drop = wrap_node(actions.node.open_file.drop)
  api.node.open.tab_drop = wrap_node(actions.node.open_file.tab_drop)
  api.node.open.replace_tree_buffer = wrap_node(actions.node.open_file.replace_tree_buffer)
  api.node.open.no_window_picker = wrap_node(actions.node.open_file.no_window_picker)
  api.node.open.vertical = wrap_node(actions.node.open_file.vertical)
  api.node.open.vertical_no_picker = wrap_node(actions.node.open_file.vertical_no_picker)
  api.node.open.horizontal = wrap_node(actions.node.open_file.horizontal)
  api.node.open.horizontal_no_picker = wrap_node(actions.node.open_file.horizontal_no_picker)
  api.node.open.tab = wrap_node(actions.node.open_file.tab)
  api.node.open.toggle_group_empty = wrap_node(actions.node.open_file.toggle_group_empty)
  api.node.open.preview = wrap_node(actions.node.open_file.preview)
  api.node.open.preview_no_picker = wrap_node(actions.node.open_file.preview_no_picker)

  api.node.show_info_popup = wrap_node(actions.node.file_popup.toggle_file_info)
  api.node.run.cmd = wrap_node(actions.node.run_command.run_file_command)
  api.node.run.system = wrap_node(actions.node.system_open.fn)

  api.node.navigate.sibling.next = wrap_node(actions.moves.sibling.next)
  api.node.navigate.sibling.prev = wrap_node(actions.moves.sibling.prev)
  api.node.navigate.sibling.first = wrap_node(actions.moves.sibling.first)
  api.node.navigate.sibling.last = wrap_node(actions.moves.sibling.last)

  api.node.navigate.parent = wrap_node(actions.moves.parent.move)
  api.node.navigate.parent_close = wrap_node(actions.moves.parent.move_close)

  api.node.navigate.git.next = actions.moves.item.git_next
  api.node.navigate.git.next_skip_gitignored = actions.moves.item.git_next_skip_gitignored
  api.node.navigate.git.next_recursive = actions.moves.item.git_next_recursive
  api.node.navigate.git.prev = actions.moves.item.git_prev
  api.node.navigate.git.prev_skip_gitignored = actions.moves.item.git_prev_skip_gitignored
  api.node.navigate.git.prev_recursive = actions.moves.item.git_prev_recursive

  api.node.navigate.diagnostics.next = actions.moves.item.diagnostics_next
  api.node.navigate.diagnostics.next_recursive = actions.moves.item.diagnostics_next_recursive
  api.node.navigate.diagnostics.prev = actions.moves.item.diagnostics_prev
  api.node.navigate.diagnostics.prev_recursive = actions.moves.item.diagnostics_prev_recursive

  api.node.navigate.opened.next = actions.moves.item.opened_next
  api.node.navigate.opened.prev = actions.moves.item.opened_prev

  api.node.expand = wrap_node(wrap_explorer("expand_node"))
  api.node.collapse = wrap_node(actions.tree.collapse.node)

  api.node.buffer.delete = wrap_node(function(node, opts) actions.node.buffer.delete(node, opts) end)
  api.node.buffer.wipe = wrap_node(function(node, opts) actions.node.buffer.wipe(node, opts) end)

  api.tree.reload_git = wrap_explorer("reload_git")

  api.filter.live.start = wrap_explorer_member("live_filter", "start_filtering")
  api.filter.live.clear = wrap_explorer_member("live_filter", "clear_filter")
  api.filter.toggle = wrap_explorer_member("filters", "toggle")
  api.filter.git.ignored.toggle = wrap_explorer_member_args("filters", "toggle", "git_ignored")
  api.filter.git.clean.toggle = wrap_explorer_member_args("filters", "toggle", "git_clean")
  api.filter.no_buffer.toggle = wrap_explorer_member_args("filters", "toggle", "no_buffer")
  api.filter.custom.toggle = wrap_explorer_member_args("filters", "toggle", "custom")
  api.filter.dotfiles.toggle = wrap_explorer_member_args("filters", "toggle", "dotfiles")
  api.filter.no_bookmark.toggle = wrap_explorer_member_args("filters", "toggle", "no_bookmark")

  api.marks.get = wrap_node(wrap_explorer_member("marks", "get"))
  api.marks.list = wrap_explorer_member("marks", "list")
  api.marks.toggle = wrap_node(wrap_explorer_member("marks", "toggle"))
  api.marks.clear = wrap_explorer_member("marks", "clear")
  api.marks.bulk.delete = wrap_explorer_member("marks", "bulk_delete")
  api.marks.bulk.trash = wrap_explorer_member("marks", "bulk_trash")
  api.marks.bulk.move = wrap_explorer_member("marks", "bulk_move")
  api.marks.navigate.next = wrap_explorer_member("marks", "navigate_next")
  api.marks.navigate.prev = wrap_explorer_member("marks", "navigate_prev")
  api.marks.navigate.select = wrap_explorer_member("marks", "navigate_select")

  api.map.keymap.current = keymap.get_keymap

  api.config.global = config.g_clone
  api.config.user = config.u_clone

  -- (Re)hydrate any legacy by mapping to concrete set above
  legacy.map_api(api)
end

return M
