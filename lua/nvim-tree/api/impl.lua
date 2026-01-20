local core = require("nvim-tree.core")
local view = require("nvim-tree.view")
local utils = require("nvim-tree.utils")
local actions = require("nvim-tree.actions")
local appearance_hi_test = require("nvim-tree.appearance.hi-test")
local help = require("nvim-tree.help")
local keymap = require("nvim-tree.keymap")
local notify = require("nvim-tree.notify")

local DirectoryNode = require("nvim-tree.node.directory")
local FileNode = require("nvim-tree.node.file")
local FileLinkNode = require("nvim-tree.node.file-link")
local RootNode = require("nvim-tree.node.root")

local M = {}

---Print error when setup not called.
---@param fn fun(...): any
---@return fun(...): any
local function wrap(fn)
  return function(...)
    if vim.g.NvimTreeSetup == 1 then
      return fn(...)
    else
      notify.error("nvim-tree setup not called")
    end
  end
end

---Invoke a method on the singleton explorer.
---Print error when setup not called.
---@param explorer_method string explorer method name
---@return fun(...): any
local function wrap_explorer(explorer_method)
  return wrap(function(...)
    local explorer = core.get_explorer()
    if explorer then
      return explorer[explorer_method](explorer, ...)
    end
  end)
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
  return wrap(function(...)
    local explorer = core.get_explorer()
    if explorer then
      return explorer[explorer_member][member_method](explorer[explorer_member], method_args, ...)
    end
  end)
end

---Invoke a member's method on the singleton explorer.
---Print error when setup not called.
---@param explorer_member string explorer member name
---@param member_method string method name to invoke on member
---@return fun(...): any
local function wrap_explorer_member(explorer_member, member_method)
  return wrap(function(...)
    local explorer = core.get_explorer()
    if explorer then
      return explorer[explorer_member][member_method](explorer[explorer_member], ...)
    end
  end)
end

---@class NodeEditOpts
---@field quit_on_open boolean|nil default false
---@field focus boolean|nil default true

---@param mode string
---@param node Node
---@param edit_opts NodeEditOpts?
local function edit(mode, node, edit_opts)
  local file_link = node:as(FileLinkNode)
  local path = file_link and file_link.link_to or node.absolute_path
  local cur_tabpage = vim.api.nvim_get_current_tabpage()

  actions.node.open_file.fn(mode, path)

  edit_opts = edit_opts or {}

  local mode_unsupported_quit_on_open = mode == "drop" or mode == "tab_drop" or mode == "edit_in_place"
  if not mode_unsupported_quit_on_open and edit_opts.quit_on_open then
    view.close(cur_tabpage)
  end

  local mode_unsupported_focus = mode == "drop" or mode == "tab_drop" or mode == "edit_in_place"
  local focus = edit_opts.focus == nil or edit_opts.focus == true
  if not mode_unsupported_focus and not focus then
    -- if mode == "tabnew" a new tab will be opened and we need to focus back to the previous tab
    if mode == "tabnew" then
      vim.cmd(":tabprev")
    end
    view.focus()
  end
end

---@param mode string
---@param toggle_group boolean?
---@return fun(node: Node, edit_opts: NodeEditOpts?)
local function open_or_expand_or_dir_up(mode, toggle_group)
  ---@param node Node
  ---@param edit_opts NodeEditOpts?
  return function(node, edit_opts)
    local root = node:as(RootNode)
    local dir = node:as(DirectoryNode)

    if root or node.name == ".." then
      actions.root.change_dir.fn("..")
    elseif dir then
      dir:expand_or_collapse(toggle_group)
    elseif not toggle_group then
      edit(mode, node, edit_opts)
    end
  end
end

function M.tree(tree)
  tree.open = wrap(actions.tree.open.fn)
  tree.focus = tree.open
  tree.toggle = wrap(actions.tree.toggle.fn)
  tree.close = wrap(view.close)
  tree.close_in_this_tab = wrap(view.close_this_tab_only)
  tree.close_in_all_tabs = wrap(view.close_all_tabs)
  tree.reload = wrap_explorer("reload_explorer")
  tree.resize = wrap(actions.tree.resize.fn)
  tree.change_root = wrap(function(...) require("nvim-tree").change_dir(...) end)
  tree.change_root_to_parent = wrap_node(wrap_explorer("dir_up"))
  tree.get_node_under_cursor = wrap_explorer("get_node_at_cursor")
  tree.get_nodes = wrap_explorer("get_nodes")
  tree.find_file = wrap(actions.tree.find_file.fn)
  tree.search_node = wrap(actions.finders.search_node.fn)
  tree.collapse_all = wrap(actions.tree.modifiers.collapse.all)
  tree.expand_all = wrap_node(actions.tree.modifiers.expand.all)
  tree.toggle_enable_filters = wrap_explorer_member("filters", "toggle")
  tree.toggle_gitignore_filter = wrap_explorer_member_args("filters", "toggle", "git_ignored")
  tree.toggle_git_clean_filter = wrap_explorer_member_args("filters", "toggle", "git_clean")
  tree.toggle_no_buffer_filter = wrap_explorer_member_args("filters", "toggle", "no_buffer")
  tree.toggle_custom_filter = wrap_explorer_member_args("filters", "toggle", "custom")
  tree.toggle_hidden_filter = wrap_explorer_member_args("filters", "toggle", "dotfiles")
  tree.toggle_no_bookmark_filter = wrap_explorer_member_args("filters", "toggle", "no_bookmark")
  tree.toggle_help = wrap(help.toggle)
  tree.is_tree_buf = wrap(utils.is_nvim_tree_buf)
  tree.is_visible = wrap(view.is_visible)
  tree.winid = wrap(view.winid)
  tree.reload_git = wrap_explorer("reload_git")
  tree.change_root_to_node = wrap_node(function(node)
    if node.name == ".." or node:is(RootNode) then
      actions.root.change_dir.fn("..")
      return
    end

    if node:is(FileNode) and node.parent ~= nil then
      actions.root.change_dir.fn(node.parent:last_group_node().absolute_path)
      return
    end

    if node:is(DirectoryNode) then
      actions.root.change_dir.fn(node:last_group_node().absolute_path)
      return
    end
  end)
end

function M.fs(fs)
  fs.create = wrap_node_or_nil(actions.fs.create_file.fn)
  fs.remove = wrap_node(actions.fs.remove_file.fn)
  fs.trash = wrap_node(actions.fs.trash.fn)
  fs.rename_node = wrap_node(actions.fs.rename_file.fn(":t"))
  fs.rename = wrap_node(actions.fs.rename_file.fn(":t"))
  fs.rename_sub = wrap_node(actions.fs.rename_file.fn(":p:h"))
  fs.rename_basename = wrap_node(actions.fs.rename_file.fn(":t:r"))
  fs.rename_full = wrap_node(actions.fs.rename_file.fn(":p"))
  fs.cut = wrap_node(wrap_explorer_member("clipboard", "cut"))
  fs.paste = wrap_node(wrap_explorer_member("clipboard", "paste"))
  fs.clear_clipboard = wrap_explorer_member("clipboard", "clear_clipboard")
  fs.print_clipboard = wrap_explorer_member("clipboard", "print_clipboard")
  fs.copy.node = wrap_node(wrap_explorer_member("clipboard", "copy"))
  fs.copy.absolute_path = wrap_node(wrap_explorer_member("clipboard", "copy_absolute_path"))
  fs.copy.filename = wrap_node(wrap_explorer_member("clipboard", "copy_filename"))
  fs.copy.basename = wrap_node(wrap_explorer_member("clipboard", "copy_basename"))
  fs.copy.relative_path = wrap_node(wrap_explorer_member("clipboard", "copy_path"))
end

function M.node(node)
  node.open.edit = wrap_node(open_or_expand_or_dir_up("edit"))
  node.open.drop = wrap_node(open_or_expand_or_dir_up("drop"))
  node.open.tab_drop = wrap_node(open_or_expand_or_dir_up("tab_drop"))
  node.open.replace_tree_buffer = wrap_node(open_or_expand_or_dir_up("edit_in_place"))
  node.open.no_window_picker = wrap_node(open_or_expand_or_dir_up("edit_no_picker"))
  node.open.vertical = wrap_node(open_or_expand_or_dir_up("vsplit"))
  node.open.vertical_no_picker = wrap_node(open_or_expand_or_dir_up("vsplit_no_picker"))
  node.open.horizontal = wrap_node(open_or_expand_or_dir_up("split"))
  node.open.horizontal_no_picker = wrap_node(open_or_expand_or_dir_up("split_no_picker"))
  node.open.tab = wrap_node(open_or_expand_or_dir_up("tabnew"))
  node.open.toggle_group_empty = wrap_node(open_or_expand_or_dir_up("toggle_group_empty", true))
  node.open.preview = wrap_node(open_or_expand_or_dir_up("preview"))
  node.open.preview_no_picker = wrap_node(open_or_expand_or_dir_up("preview_no_picker"))
  node.show_info_popup = wrap_node(actions.node.file_popup.toggle_file_info)
  node.run.cmd = wrap_node(actions.node.run_command.run_file_command)
  node.run.system = wrap_node(actions.node.system_open.fn)
  node.navigate.sibling.next = wrap_node(actions.moves.sibling.fn("next"))
  node.navigate.sibling.prev = wrap_node(actions.moves.sibling.fn("prev"))
  node.navigate.sibling.first = wrap_node(actions.moves.sibling.fn("first"))
  node.navigate.sibling.last = wrap_node(actions.moves.sibling.fn("last"))
  node.navigate.parent = wrap_node(actions.moves.parent.fn(false))
  node.navigate.parent_close = wrap_node(actions.moves.parent.fn(true))
  node.navigate.git.next = wrap_node(actions.moves.item.fn({ where = "next", what = "git" }))
  node.navigate.git.next_skip_gitignored = wrap_node(actions.moves.item.fn({ where = "next", what = "git", skip_gitignored = true }))
  node.navigate.git.next_recursive = wrap_node(actions.moves.item.fn({ where = "next", what = "git", recurse = true }))
  node.navigate.git.prev = wrap_node(actions.moves.item.fn({ where = "prev", what = "git" }))
  node.navigate.git.prev_skip_gitignored = wrap_node(actions.moves.item.fn({ where = "prev", what = "git", skip_gitignored = true }))
  node.navigate.git.prev_recursive = wrap_node(actions.moves.item.fn({ where = "prev", what = "git", recurse = true }))
  node.navigate.diagnostics.next = wrap_node(actions.moves.item.fn({ where = "next", what = "diag" }))
  node.navigate.diagnostics.next_recursive = wrap_node(actions.moves.item.fn({ where = "next", what = "diag", recurse = true }))
  node.navigate.diagnostics.prev = wrap_node(actions.moves.item.fn({ where = "prev", what = "diag" }))
  node.navigate.diagnostics.prev_recursive = wrap_node(actions.moves.item.fn({ where = "prev", what = "diag", recurse = true }))
  node.navigate.opened.next = wrap_node(actions.moves.item.fn({ where = "next", what = "opened" }))
  node.navigate.opened.prev = wrap_node(actions.moves.item.fn({ where = "prev", what = "opened" }))
  node.expand = wrap_node(actions.tree.modifiers.expand.node)
  node.collapse = wrap_node(actions.tree.modifiers.collapse.node)
  node.buffer.delete = wrap_node(function(n, opts) actions.node.buffer.delete(n, opts) end)
  node.buffer.wipe = wrap_node(function(n, opts) actions.node.buffer.wipe(n, opts) end)
end

function M.events(events)
  events.subscribe = require("nvim-tree.events").subscribe
  events.Event = require("nvim-tree.events").Event
end

function M.filter(filter)
  filter.live_filter.start = wrap_explorer_member("live_filter", "start_filtering")
  filter.live_filter.clear = wrap_explorer_member("live_filter", "clear_filter")
end

function M.marks(marks)
  marks.get = wrap_node(wrap_explorer_member("marks", "get"))
  marks.list = wrap_explorer_member("marks", "list")
  marks.toggle = wrap_node(wrap_explorer_member("marks", "toggle"))
  marks.clear = wrap_explorer_member("marks", "clear")
  marks.bulk.delete = wrap_explorer_member("marks", "bulk_delete")
  marks.bulk.trash = wrap_explorer_member("marks", "bulk_trash")
  marks.bulk.move = wrap_explorer_member("marks", "bulk_move")
  marks.navigate.next = wrap_explorer_member("marks", "navigate_next")
  marks.navigate.prev = wrap_explorer_member("marks", "navigate_prev")
  marks.navigate.select = wrap_explorer_member("marks", "navigate_select")
end

function M.map(map)
  map.get_keymap = wrap(keymap.get_keymap)
  map.get_keymap_default = wrap(keymap.get_keymap_default)
  map.default_on_attach = keymap.default_on_attach
end

function M.health(health)
  health.hi_test = wrap(appearance_hi_test)
end

function M.commands(commands)
  commands.get = wrap(function() return require("nvim-tree.commands").get() end)
end

return M
