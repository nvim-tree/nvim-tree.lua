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

-- hydrates meta api definitions with implementations
return function(api)
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

  api.tree.open = wrap(actions.tree.open.fn)
  api.tree.focus = api.tree.open

  api.tree.toggle = wrap(actions.tree.toggle.fn)
  api.tree.close = wrap(view.close)
  api.tree.close_in_this_tab = wrap(view.close_this_tab_only)
  api.tree.close_in_all_tabs = wrap(view.close_all_tabs)
  api.tree.reload = wrap_explorer("reload_explorer")

  api.tree.resize = wrap(actions.tree.resize.fn)

  api.tree.change_root = wrap(function(...)
    require("nvim-tree").change_dir(...)
  end)

  api.tree.change_root_to_node = wrap_node(function(node)
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

  api.tree.change_root_to_parent = wrap_node(wrap_explorer("dir_up"))
  api.tree.get_node_under_cursor = wrap_explorer("get_node_at_cursor")
  api.tree.get_nodes = wrap_explorer("get_nodes")

  api.tree.find_file = wrap(actions.tree.find_file.fn)
  api.tree.search_node = wrap(actions.finders.search_node.fn)

  api.tree.collapse_all = wrap(actions.tree.modifiers.collapse.all)

  api.tree.expand_all = wrap_node(actions.tree.modifiers.expand.all)
  api.tree.toggle_help = wrap(help.toggle)
  api.tree.is_tree_buf = wrap(utils.is_nvim_tree_buf)

  api.tree.is_visible = wrap(view.is_visible)

  api.tree.winid = wrap(view.winid)

  api.fs.create = wrap_node_or_nil(actions.fs.create_file.fn)
  api.fs.remove = wrap_node(actions.fs.remove_file.fn)
  api.fs.trash = wrap_node(actions.fs.trash.fn)
  api.fs.rename_node = wrap_node(actions.fs.rename_file.fn(":t"))
  api.fs.rename = wrap_node(actions.fs.rename_file.fn(":t"))
  api.fs.rename_sub = wrap_node(actions.fs.rename_file.fn(":p:h"))
  api.fs.rename_basename = wrap_node(actions.fs.rename_file.fn(":t:r"))
  api.fs.rename_full = wrap_node(actions.fs.rename_file.fn(":p"))
  api.fs.cut = wrap_node(wrap_explorer_member("clipboard", "cut"))
  api.fs.paste = wrap_node(wrap_explorer_member("clipboard", "paste"))
  api.fs.clear_clipboard = wrap_explorer_member("clipboard", "clear_clipboard")
  api.fs.print_clipboard = wrap_explorer_member("clipboard", "print_clipboard")
  api.fs.copy.node = wrap_node(wrap_explorer_member("clipboard", "copy"))
  api.fs.copy.absolute_path = wrap_node(wrap_explorer_member("clipboard", "copy_absolute_path"))
  api.fs.copy.filename = wrap_node(wrap_explorer_member("clipboard", "copy_filename"))
  api.fs.copy.basename = wrap_node(wrap_explorer_member("clipboard", "copy_basename"))
  api.fs.copy.relative_path = wrap_node(wrap_explorer_member("clipboard", "copy_path"))
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

  api.node.open.edit = wrap_node(open_or_expand_or_dir_up("edit"))
  api.node.open.drop = wrap_node(open_or_expand_or_dir_up("drop"))
  api.node.open.tab_drop = wrap_node(open_or_expand_or_dir_up("tab_drop"))
  api.node.open.replace_tree_buffer = wrap_node(open_or_expand_or_dir_up("edit_in_place"))
  api.node.open.no_window_picker = wrap_node(open_or_expand_or_dir_up("edit_no_picker"))
  api.node.open.vertical = wrap_node(open_or_expand_or_dir_up("vsplit"))
  api.node.open.vertical_no_picker = wrap_node(open_or_expand_or_dir_up("vsplit_no_picker"))
  api.node.open.horizontal = wrap_node(open_or_expand_or_dir_up("split"))
  api.node.open.horizontal_no_picker = wrap_node(open_or_expand_or_dir_up("split_no_picker"))
  api.node.open.tab = wrap_node(open_or_expand_or_dir_up("tabnew"))
  api.node.open.toggle_group_empty = wrap_node(open_or_expand_or_dir_up("toggle_group_empty", true))
  api.node.open.preview = wrap_node(open_or_expand_or_dir_up("preview"))
  api.node.open.preview_no_picker = wrap_node(open_or_expand_or_dir_up("preview_no_picker"))

  api.node.show_info_popup = wrap_node(actions.node.file_popup.toggle_file_info)
  api.node.run.cmd = wrap_node(actions.node.run_command.run_file_command)
  api.node.run.system = wrap_node(actions.node.system_open.fn)

  api.node.navigate.sibling.next = wrap_node(actions.moves.sibling.fn("next"))
  api.node.navigate.sibling.prev = wrap_node(actions.moves.sibling.fn("prev"))
  api.node.navigate.sibling.first = wrap_node(actions.moves.sibling.fn("first"))
  api.node.navigate.sibling.last = wrap_node(actions.moves.sibling.fn("last"))
  api.node.navigate.parent = wrap_node(actions.moves.parent.fn(false))
  api.node.navigate.parent_close = wrap_node(actions.moves.parent.fn(true))
  api.node.navigate.git.next = wrap_node(actions.moves.item.fn({ where = "next", what = "git" }))
  api.node.navigate.git.next_skip_gitignored = wrap_node(actions.moves.item.fn({ where = "next", what = "git", skip_gitignored = true }))
  api.node.navigate.git.next_recursive = wrap_node(actions.moves.item.fn({ where = "next", what = "git", recurse = true }))
  api.node.navigate.git.prev = wrap_node(actions.moves.item.fn({ where = "prev", what = "git" }))
  api.node.navigate.git.prev_skip_gitignored = wrap_node(actions.moves.item.fn({ where = "prev", what = "git", skip_gitignored = true }))
  api.node.navigate.git.prev_recursive = wrap_node(actions.moves.item.fn({ where = "prev", what = "git", recurse = true }))
  api.node.navigate.diagnostics.next = wrap_node(actions.moves.item.fn({ where = "next", what = "diag" }))
  api.node.navigate.diagnostics.next_recursive = wrap_node(actions.moves.item.fn({ where = "next", what = "diag", recurse = true }))
  api.node.navigate.diagnostics.prev = wrap_node(actions.moves.item.fn({ where = "prev", what = "diag" }))
  api.node.navigate.diagnostics.prev_recursive = wrap_node(actions.moves.item.fn({ where = "prev", what = "diag", recurse = true }))
  api.node.navigate.opened.next = wrap_node(actions.moves.item.fn({ where = "next", what = "opened" }))
  api.node.navigate.opened.prev = wrap_node(actions.moves.item.fn({ where = "prev", what = "opened" }))

  api.node.expand = wrap_node(actions.tree.modifiers.expand.node)
  api.node.collapse = wrap_node(actions.tree.modifiers.collapse.node)

  ---@class ApiNodeDeleteWipeBufferOpts
  ---@field force boolean|nil default false

  api.node.buffer.delete = wrap_node(function(node, opts)
    actions.node.buffer.delete(node, opts)
  end)
  api.node.buffer.wipe = wrap_node(function(node, opts)
    actions.node.buffer.wipe(node, opts)
  end)

  api.tree.reload_git = wrap_explorer("reload_git")

  api.events.subscribe = events.subscribe
  api.events.Event = events.Event

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

  api.map.get_keymap = wrap(keymap.get_keymap)
  api.map.get_keymap_default = wrap(keymap.get_keymap_default)
  api.map.default_on_attach = keymap.default_on_attach

  api.health.hi_test = wrap(appearance_hi_test)

  api.commands.get = wrap(function()
    return require("nvim-tree.commands").get()
  end)

  api.decorator = {}
  ---Create a decorator class by calling :extend()
  ---See :help nvim-tree-decorators
  ---@type nvim_tree.api.decorator.UserDecorator
  api.decorator.UserDecorator = UserDecorator --[[@as nvim_tree.api.decorator.UserDecorator]]


  --
  --Legacy API mappings
  --
  api.git = {
    reload = api.tree.reload_git,
  }

  api.live_filter = {
    start = api.filter.live.start,
    clear = api.filter.live.clear,
  }
  api.tree.toggle_enable_filters = api.filter.toggle
  api.tree.toggle_gitignore_filter = api.filter.git.ignored.toggle
  api.tree.toggle_git_clean_filter = api.filter.git.clean.toggle
  api.tree.toggle_no_buffer_filter = api.filter.no_buffer.toggle
  api.tree.toggle_custom_filter = api.filter.custom.toggle
  api.tree.toggle_hidden_filter = api.filter.dotfiles.toggle
  api.tree.toggle_no_bookmark_filter = api.filter.no_bookmark.toggle

  api.config = {
    mappings = {
      get_keymap = api.map.get_keymap,
      get_keymap_default = api.map.get_keymap_default,
      default_on_attach = api.map.default_on_attach,
    }
  }

  api.diagnostics = {
    hi_test = api.health.hi_test,
  }
end
