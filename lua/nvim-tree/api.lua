local lib = require "nvim-tree.lib"
local view = require "nvim-tree.view"
local utils = require "nvim-tree.utils"
local actions = require "nvim-tree.actions"
local appearance_diagnostics = require "nvim-tree.appearance.diagnostics"
local events = require "nvim-tree.events"
local help = require "nvim-tree.help"
local live_filter = require "nvim-tree.live-filter"
local marks = require "nvim-tree.marks"
local marks_navigation = require "nvim-tree.marks.navigation"
local marks_bulk_delete = require "nvim-tree.marks.bulk-delete"
local marks_bulk_trash = require "nvim-tree.marks.bulk-trash"
local marks_bulk_move = require "nvim-tree.marks.bulk-move"
local keymap = require "nvim-tree.keymap"
local notify = require "nvim-tree.notify"

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
}

--- Do nothing when setup not called.
--- f function to invoke
---@param f function
local function wrap(f)
  return function(...)
    if vim.g.NvimTreeSetup == 1 then
      return f(...)
    else
      notify.error "nvim-tree setup not called"
    end
  end
end

---Inject the node as the first argument if absent.
---@param fn function function to invoke
local function wrap_node(fn)
  return function(node, ...)
    node = node or lib.get_node_at_cursor()
    if node then
      fn(node, ...)
    end
  end
end

---Inject the node or nil as the first argument if absent.
---@param fn function function to invoke
local function wrap_node_or_nil(fn)
  return function(node, ...)
    node = node or lib.get_node_at_cursor()
    fn(node, ...)
  end
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
Api.tree.reload = wrap(actions.reloaders.reload_explorer)

Api.tree.change_root = wrap(function(...)
  require("nvim-tree").change_dir(...)
end)

Api.tree.change_root_to_node = wrap_node(function(node)
  if node.name == ".." then
    actions.root.change_dir.fn ".."
  elseif node.nodes ~= nil then
    actions.root.change_dir.fn(lib.get_last_group_node(node).absolute_path)
  end
end)

Api.tree.change_root_to_parent = wrap_node(actions.root.dir_up.fn)
Api.tree.get_node_under_cursor = wrap(lib.get_node_at_cursor)
Api.tree.get_nodes = wrap(lib.get_nodes)

---@class ApiTreeFindFileOpts
---@field buf string|number|nil
---@field open boolean|nil default false
---@field current_window boolean|nil default false
---@field winid number|nil
---@field update_root boolean|nil default false
---@field focus boolean|nil default false

Api.tree.find_file = wrap(actions.tree.find_file.fn)
Api.tree.search_node = wrap(actions.finders.search_node.fn)
Api.tree.collapse_all = wrap(actions.tree.modifiers.collapse_all.fn)
Api.tree.expand_all = wrap_node(actions.tree.modifiers.expand_all.fn)
Api.tree.toggle_gitignore_filter = wrap(actions.tree.modifiers.toggles.git_ignored)
Api.tree.toggle_git_clean_filter = wrap(actions.tree.modifiers.toggles.git_clean)
Api.tree.toggle_no_buffer_filter = wrap(actions.tree.modifiers.toggles.no_buffer)
Api.tree.toggle_custom_filter = wrap(actions.tree.modifiers.toggles.custom)
Api.tree.toggle_hidden_filter = wrap(actions.tree.modifiers.toggles.dotfiles)
Api.tree.toggle_no_bookmark_filter = wrap(actions.tree.modifiers.toggles.no_bookmark)
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
Api.fs.rename_node = wrap_node(actions.fs.rename_file.fn ":t")
Api.fs.rename = wrap_node(actions.fs.rename_file.fn ":t")
Api.fs.rename_sub = wrap_node(actions.fs.rename_file.fn ":p:h")
Api.fs.rename_basename = wrap_node(actions.fs.rename_file.fn ":t:r")
Api.fs.rename_full = wrap_node(actions.fs.rename_file.fn ":p")
Api.fs.cut = wrap_node(actions.fs.copy_paste.cut)
Api.fs.paste = wrap_node(actions.fs.copy_paste.paste)
Api.fs.clear_clipboard = wrap(actions.fs.copy_paste.clear_clipboard)
Api.fs.print_clipboard = wrap(actions.fs.copy_paste.print_clipboard)
Api.fs.copy.node = wrap_node(actions.fs.copy_paste.copy)
Api.fs.copy.absolute_path = wrap_node(actions.fs.copy_paste.copy_absolute_path)
Api.fs.copy.filename = wrap_node(actions.fs.copy_paste.copy_filename)
Api.fs.copy.relative_path = wrap_node(actions.fs.copy_paste.copy_path)

---@param mode string
---@param node table
local function edit(mode, node)
  local path = node.absolute_path
  if node.link_to and not node.nodes then
    path = node.link_to
  end
  actions.node.open_file.fn(mode, path)
end

---@param mode string
---@return fun(node: table)
local function open_or_expand_or_dir_up(mode, toggle_group)
  return function(node)
    if node.name == ".." then
      actions.root.change_dir.fn ".."
    elseif node.nodes then
      lib.expand_or_collapse(node, toggle_group)
    elseif not toggle_group then
      edit(mode, node)
    end
  end
end

Api.node.open.edit = wrap_node(open_or_expand_or_dir_up "edit")
Api.node.open.drop = wrap_node(open_or_expand_or_dir_up "drop")
Api.node.open.tab_drop = wrap_node(open_or_expand_or_dir_up "tab_drop")
Api.node.open.replace_tree_buffer = wrap_node(open_or_expand_or_dir_up "edit_in_place")
Api.node.open.no_window_picker = wrap_node(open_or_expand_or_dir_up "edit_no_picker")
Api.node.open.vertical = wrap_node(open_or_expand_or_dir_up "vsplit")
Api.node.open.horizontal = wrap_node(open_or_expand_or_dir_up "split")
Api.node.open.tab = wrap_node(open_or_expand_or_dir_up "tabnew")
Api.node.open.toggle_group_empty = wrap_node(open_or_expand_or_dir_up("toggle_group_empty", true))
Api.node.open.preview = wrap_node(open_or_expand_or_dir_up "preview")
Api.node.open.preview_no_picker = wrap_node(open_or_expand_or_dir_up "preview_no_picker")

Api.node.show_info_popup = wrap_node(actions.node.file_popup.toggle_file_info)
Api.node.run.cmd = wrap_node(actions.node.run_command.run_file_command)
Api.node.run.system = wrap_node(actions.node.system_open.fn)

Api.node.navigate.sibling.next = wrap_node(actions.moves.sibling.fn "next")
Api.node.navigate.sibling.prev = wrap_node(actions.moves.sibling.fn "prev")
Api.node.navigate.sibling.first = wrap_node(actions.moves.sibling.fn "first")
Api.node.navigate.sibling.last = wrap_node(actions.moves.sibling.fn "last")
Api.node.navigate.parent = wrap_node(actions.moves.parent.fn(false))
Api.node.navigate.parent_close = wrap_node(actions.moves.parent.fn(true))
Api.node.navigate.git.next = wrap_node(actions.moves.item.fn { where = "next", what = "git" })
Api.node.navigate.git.next_skip_gitignored = wrap_node(actions.moves.item.fn { where = "next", what = "git", skip_gitignored = true })
Api.node.navigate.git.next_recursive = wrap_node(actions.moves.item.fn { where = "next", what = "git", recurse = true })
Api.node.navigate.git.prev = wrap_node(actions.moves.item.fn { where = "prev", what = "git" })
Api.node.navigate.git.prev_skip_gitignored = wrap_node(actions.moves.item.fn { where = "prev", what = "git", skip_gitignored = true })
Api.node.navigate.git.prev_recursive = wrap_node(actions.moves.item.fn { where = "prev", what = "git", recurse = true })
Api.node.navigate.diagnostics.next = wrap_node(actions.moves.item.fn { where = "next", what = "diag" })
Api.node.navigate.diagnostics.next_recursive = wrap_node(actions.moves.item.fn { where = "next", what = "diag", recurse = true })
Api.node.navigate.diagnostics.prev = wrap_node(actions.moves.item.fn { where = "prev", what = "diag" })
Api.node.navigate.diagnostics.prev_recursive = wrap_node(actions.moves.item.fn { where = "prev", what = "diag", recurse = true })
Api.node.navigate.opened.next = wrap_node(actions.moves.item.fn { where = "next", what = "opened" })
Api.node.navigate.opened.prev = wrap_node(actions.moves.item.fn { where = "prev", what = "opened" })

Api.git.reload = wrap(actions.reloaders.reload_git)

Api.events.subscribe = events.subscribe
Api.events.Event = events.Event

Api.live_filter.start = wrap(live_filter.start_filtering)
Api.live_filter.clear = wrap(live_filter.clear_filter)

Api.marks.get = wrap_node(marks.get_mark)
Api.marks.list = wrap(marks.get_marks)
Api.marks.toggle = wrap_node(marks.toggle_mark)
Api.marks.clear = wrap(marks.clear_marks)
Api.marks.bulk.delete = wrap(marks_bulk_delete.bulk_delete)
Api.marks.bulk.trash = wrap(marks_bulk_trash.bulk_trash)
Api.marks.bulk.move = wrap(marks_bulk_move.bulk_move)
Api.marks.navigate.next = wrap(marks_navigation.next)
Api.marks.navigate.prev = wrap(marks_navigation.prev)
Api.marks.navigate.select = wrap(marks_navigation.select)

Api.config.mappings.get_keymap = wrap(keymap.get_keymap)
Api.config.mappings.get_keymap_default = wrap(keymap.get_keymap_default)
Api.config.mappings.default_on_attach = keymap.default_on_attach

Api.diagnostics.hi_test = wrap(appearance_diagnostics.hi_test)

Api.commands.get = wrap(function()
  return require("nvim-tree.commands").get()
end)

return Api
