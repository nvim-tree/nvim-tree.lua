local core = require("nvim-tree.core")
local view = require("nvim-tree.view")
local utils = require("nvim-tree.utils")
local actions = require("nvim-tree.actions")
local appearance_hi_test = require("nvim-tree.appearance.hi-test")
local events = require("nvim-tree.events")
local help = require("nvim-tree.help")
local keymap = require("nvim-tree.keymap")
local notify = require("nvim-tree.notify")

local DirectoryNode = require("nvim-tree.node.directory")
local FileNode = require("nvim-tree.node.file")
local FileLinkNode = require("nvim-tree.node.file-link")
local RootNode = require("nvim-tree.node.root")
local UserDecorator = require("nvim-tree.renderer.decorator.user")

local Api = {
  tree = {},
  node = {
    navigate = {
      sibling = {},
      git = {},
      diagnostics = {},
      opened = {},
    },
    run = {},
    open = {},
    buffer = {},
  },
  events = {},
  marks = {
    bulk = {},
    navigate = {},
  },
  fs = {
    copy = {},
  },
  git = {},
  live_filter = {},
  config = {
    mappings = {},
  },
  commands = {},
  diagnostics = {},
  decorator = {},
}

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

---@class ApiTreeOpenOpts
---@field path string|nil path
---@field current_window boolean|nil default false
---@field winid number|nil
---@field find_file boolean|nil default false
---@field update_root boolean|nil default false

Api.tree.open = wrap(actions.tree.open.fn)
Api.tree.focus = Api.tree.open

---@class ApiTreeToggleOpts
---@field path string|nil
---@field current_window boolean|nil default false
---@field winid number|nil
---@field find_file boolean|nil default false
---@field update_root boolean|nil default false
---@field focus boolean|nil default true

Api.tree.toggle = wrap(actions.tree.toggle.fn)
Api.tree.close = wrap(view.close)
Api.tree.close_in_this_tab = wrap(view.close_this_tab_only)
Api.tree.close_in_all_tabs = wrap(view.close_all_tabs)
Api.tree.reload = wrap_explorer("reload_explorer")

---@class ApiTreeResizeOpts
---@field width string|function|number|table|nil
---@field absolute number|nil
---@field relative number|nil

Api.tree.resize = wrap(actions.tree.resize.fn)

Api.tree.change_root = wrap(function(...)
  require("nvim-tree").change_dir(...)
end)

Api.tree.change_root_to_node = wrap_node(function(node)
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

Api.tree.change_root_to_parent = wrap_node(wrap_explorer("dir_up"))
Api.tree.get_node_under_cursor = wrap_explorer("get_node_at_cursor")
Api.tree.get_nodes = wrap_explorer("get_nodes")

---@class ApiTreeFindFileOpts
---@field buf string|number|nil
---@field open boolean|nil default false
---@field current_window boolean|nil default false
---@field winid number|nil
---@field update_root boolean|nil default false
---@field focus boolean|nil default false

Api.tree.find_file = wrap(actions.tree.find_file.fn)
Api.tree.search_node = wrap(actions.finders.search_node.fn)

---@class ApiCollapseOpts
---@field keep_buffers boolean|nil default false

Api.tree.collapse_all = wrap(actions.tree.modifiers.collapse.all)

---@class ApiTreeExpandOpts
---@field expand_until (fun(expansion_count: integer, node: Node): boolean)|nil

Api.tree.expand_all = wrap_node(actions.tree.modifiers.expand.all)
Api.tree.toggle_enable_filters = wrap_explorer_member("filters", "toggle")
Api.tree.toggle_gitignore_filter = wrap_explorer_member_args("filters", "toggle", "git_ignored")
Api.tree.toggle_git_clean_filter = wrap_explorer_member_args("filters", "toggle", "git_clean")
Api.tree.toggle_no_buffer_filter = wrap_explorer_member_args("filters", "toggle", "no_buffer")
Api.tree.toggle_custom_filter = wrap_explorer_member_args("filters", "toggle", "custom")
Api.tree.toggle_hidden_filter = wrap_explorer_member_args("filters", "toggle", "dotfiles")
Api.tree.toggle_no_bookmark_filter = wrap_explorer_member_args("filters", "toggle", "no_bookmark")
Api.tree.toggle_help = wrap(help.toggle)
Api.tree.is_tree_buf = wrap(utils.is_nvim_tree_buf)

---@class ApiTreeIsVisibleOpts
---@field tabpage number|nil
---@field any_tabpage boolean|nil default false

Api.tree.is_visible = wrap(view.is_visible)

---@class ApiTreeWinIdOpts
---@field tabpage number|nil default nil

Api.tree.winid = wrap(view.winid)

Api.fs.create = wrap_node_or_nil(actions.fs.create_file.fn)
Api.fs.remove = wrap_node(actions.fs.remove_file.fn)
Api.fs.trash = wrap_node(actions.fs.trash.fn)
Api.fs.rename_node = wrap_node(actions.fs.rename_file.fn(":t"))
Api.fs.rename = wrap_node(actions.fs.rename_file.fn(":t"))
Api.fs.rename_sub = wrap_node(actions.fs.rename_file.fn(":p:h"))
Api.fs.rename_basename = wrap_node(actions.fs.rename_file.fn(":t:r"))
Api.fs.rename_full = wrap_node(actions.fs.rename_file.fn(":p"))
Api.fs.cut = wrap_node(wrap_explorer_member("clipboard", "cut"))
Api.fs.paste = wrap_node(wrap_explorer_member("clipboard", "paste"))
Api.fs.clear_clipboard = wrap_explorer_member("clipboard", "clear_clipboard")
Api.fs.print_clipboard = wrap_explorer_member("clipboard", "print_clipboard")
Api.fs.copy.node = wrap_node(wrap_explorer_member("clipboard", "copy"))
Api.fs.copy.absolute_path = wrap_node(wrap_explorer_member("clipboard", "copy_absolute_path"))
Api.fs.copy.filename = wrap_node(wrap_explorer_member("clipboard", "copy_filename"))
Api.fs.copy.basename = wrap_node(wrap_explorer_member("clipboard", "copy_basename"))
Api.fs.copy.relative_path = wrap_node(wrap_explorer_member("clipboard", "copy_path"))
---
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

Api.node.open.edit = wrap_node(open_or_expand_or_dir_up("edit"))
Api.node.open.drop = wrap_node(open_or_expand_or_dir_up("drop"))
Api.node.open.tab_drop = wrap_node(open_or_expand_or_dir_up("tab_drop"))
Api.node.open.replace_tree_buffer = wrap_node(open_or_expand_or_dir_up("edit_in_place"))
Api.node.open.no_window_picker = wrap_node(open_or_expand_or_dir_up("edit_no_picker"))
Api.node.open.vertical = wrap_node(open_or_expand_or_dir_up("vsplit"))
Api.node.open.vertical_no_picker = wrap_node(open_or_expand_or_dir_up("vsplit_no_picker"))
Api.node.open.horizontal = wrap_node(open_or_expand_or_dir_up("split"))
Api.node.open.horizontal_no_picker = wrap_node(open_or_expand_or_dir_up("split_no_picker"))
Api.node.open.tab = wrap_node(open_or_expand_or_dir_up("tabnew"))
Api.node.open.toggle_group_empty = wrap_node(open_or_expand_or_dir_up("toggle_group_empty", true))
Api.node.open.preview = wrap_node(open_or_expand_or_dir_up("preview"))
Api.node.open.preview_no_picker = wrap_node(open_or_expand_or_dir_up("preview_no_picker"))

Api.node.show_info_popup = wrap_node(actions.node.file_popup.toggle_file_info)
Api.node.run.cmd = wrap_node(actions.node.run_command.run_file_command)
Api.node.run.system = wrap_node(actions.node.system_open.fn)

Api.node.navigate.sibling.next = wrap_node(actions.moves.sibling.fn("next"))
Api.node.navigate.sibling.prev = wrap_node(actions.moves.sibling.fn("prev"))
Api.node.navigate.sibling.first = wrap_node(actions.moves.sibling.fn("first"))
Api.node.navigate.sibling.last = wrap_node(actions.moves.sibling.fn("last"))
Api.node.navigate.parent = wrap_node(actions.moves.parent.fn(false))
Api.node.navigate.parent_close = wrap_node(actions.moves.parent.fn(true))
Api.node.navigate.git.next = wrap_node(actions.moves.item.fn({ where = "next", what = "git" }))
Api.node.navigate.git.next_skip_gitignored = wrap_node(actions.moves.item.fn({ where = "next", what = "git", skip_gitignored = true }))
Api.node.navigate.git.next_recursive = wrap_node(actions.moves.item.fn({ where = "next", what = "git", recurse = true }))
Api.node.navigate.git.prev = wrap_node(actions.moves.item.fn({ where = "prev", what = "git" }))
Api.node.navigate.git.prev_skip_gitignored = wrap_node(actions.moves.item.fn({ where = "prev", what = "git", skip_gitignored = true }))
Api.node.navigate.git.prev_recursive = wrap_node(actions.moves.item.fn({ where = "prev", what = "git", recurse = true }))
Api.node.navigate.diagnostics.next = wrap_node(actions.moves.item.fn({ where = "next", what = "diag" }))
Api.node.navigate.diagnostics.next_recursive = wrap_node(actions.moves.item.fn({ where = "next", what = "diag", recurse = true }))
Api.node.navigate.diagnostics.prev = wrap_node(actions.moves.item.fn({ where = "prev", what = "diag" }))
Api.node.navigate.diagnostics.prev_recursive = wrap_node(actions.moves.item.fn({ where = "prev", what = "diag", recurse = true }))
Api.node.navigate.opened.next = wrap_node(actions.moves.item.fn({ where = "next", what = "opened" }))
Api.node.navigate.opened.prev = wrap_node(actions.moves.item.fn({ where = "prev", what = "opened" }))

Api.node.expand = wrap_node(actions.tree.modifiers.expand.node)
Api.node.collapse = wrap_node(actions.tree.modifiers.collapse.node)

---@class ApiNodeDeleteWipeBufferOpts
---@field force boolean|nil default false

Api.node.buffer.delete = wrap_node(function(node, opts)
  actions.node.buffer.delete(node, opts)
end)
Api.node.buffer.wipe = wrap_node(function(node, opts)
  actions.node.buffer.wipe(node, opts)
end)

Api.git.reload = wrap_explorer("reload_git")

Api.events.subscribe = events.subscribe
Api.events.Event = events.Event

Api.live_filter.start = wrap_explorer_member("live_filter", "start_filtering")
Api.live_filter.clear = wrap_explorer_member("live_filter", "clear_filter")

Api.marks.get = wrap_node(wrap_explorer_member("marks", "get"))
Api.marks.list = wrap_explorer_member("marks", "list")
Api.marks.toggle = wrap_node(wrap_explorer_member("marks", "toggle"))
Api.marks.clear = wrap_explorer_member("marks", "clear")
Api.marks.bulk.delete = wrap_explorer_member("marks", "bulk_delete")
Api.marks.bulk.trash = wrap_explorer_member("marks", "bulk_trash")
Api.marks.bulk.move = wrap_explorer_member("marks", "bulk_move")
Api.marks.navigate.next = wrap_explorer_member("marks", "navigate_next")
Api.marks.navigate.prev = wrap_explorer_member("marks", "navigate_prev")
Api.marks.navigate.select = wrap_explorer_member("marks", "navigate_select")

Api.config.mappings.get_keymap = wrap(keymap.get_keymap)
Api.config.mappings.get_keymap_default = wrap(keymap.get_keymap_default)
Api.config.mappings.default_on_attach = keymap.default_on_attach

Api.diagnostics.hi_test = wrap(appearance_hi_test)

Api.commands.get = wrap(function()
  return require("nvim-tree.commands").get()
end)

---Create a decorator class by calling :extend()
---See :help nvim-tree-decorators
---@type nvim_tree.api.decorator.UserDecorator
Api.decorator.UserDecorator = UserDecorator --[[@as nvim_tree.api.decorator.UserDecorator]]

return Api
