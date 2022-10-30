local view = require "nvim-tree.view"
local lib = require "nvim-tree.lib"

local M = {}

local Actions = {
  close = view.close,

  -- Tree modifiers
  collapse_all = require("nvim-tree.actions.tree-modifiers.collapse-all").fn,
  expand_all = require("nvim-tree.actions.tree-modifiers.expand-all").fn,
  toggle_dotfiles = require("nvim-tree.actions.tree-modifiers.toggles").dotfiles,
  toggle_custom = require("nvim-tree.actions.tree-modifiers.toggles").custom,
  toggle_git_ignored = require("nvim-tree.actions.tree-modifiers.toggles").git_ignored,

  -- Filesystem operations
  copy_absolute_path = require("nvim-tree.actions.fs.copy-paste").copy_absolute_path,
  copy_name = require("nvim-tree.actions.fs.copy-paste").copy_filename,
  copy_path = require("nvim-tree.actions.fs.copy-paste").copy_path,
  copy = require("nvim-tree.actions.fs.copy-paste").copy,
  create = require("nvim-tree.actions.fs.create-file").fn,
  cut = require("nvim-tree.actions.fs.copy-paste").cut,
  full_rename = require("nvim-tree.actions.fs.rename-file").fn(true),
  paste = require("nvim-tree.actions.fs.copy-paste").paste,
  trash = require("nvim-tree.actions.fs.trash").fn,
  remove = require("nvim-tree.actions.fs.remove-file").fn,
  rename = require("nvim-tree.actions.fs.rename-file").fn(false),

  -- Movements in tree
  close_node = require("nvim-tree.actions.moves.parent").fn(true),
  first_sibling = require("nvim-tree.actions.moves.sibling").fn "first",
  last_sibling = require("nvim-tree.actions.moves.sibling").fn "last",
  next_diag_item = require("nvim-tree.actions.moves.item").fn("next", "diag"),
  next_git_item = require("nvim-tree.actions.moves.item").fn("next", "git"),
  next_sibling = require("nvim-tree.actions.moves.sibling").fn "next",
  parent_node = require("nvim-tree.actions.moves.parent").fn(false),
  prev_diag_item = require("nvim-tree.actions.moves.item").fn("prev", "diag"),
  prev_git_item = require("nvim-tree.actions.moves.item").fn("prev", "git"),
  prev_sibling = require("nvim-tree.actions.moves.sibling").fn "prev",

  -- Other types
  refresh = require("nvim-tree.actions.reloaders.reloaders").reload_explorer,
  dir_up = require("nvim-tree.actions.root.dir-up").fn,
  search_node = require("nvim-tree.actions.finders.search-node").fn,
  run_file_command = require("nvim-tree.actions.node.run-command").run_file_command,
  toggle_file_info = require("nvim-tree.actions.node.file-popup").toggle_file_info,
  system_open = require("nvim-tree.actions.node.system-open").fn,
  toggle_mark = require("nvim-tree.marks").toggle_mark,
  bulk_move = require("nvim-tree.marks.bulk-move").bulk_move,
}

local function handle_action_on_help_ui(action)
  if action == "close" or action == "toggle_help" then
    require("nvim-tree.actions.tree-modifiers.toggles").help()
  end
end

local function handle_filter_actions(action)
  if action == "live_filter" then
    require("nvim-tree.live-filter").start_filtering()
  elseif action == "clear_live_filter" then
    require("nvim-tree.live-filter").clear_filter()
  end
end

local function change_dir_action(node)
  if node.name == ".." then
    require("nvim-tree.actions.root.change-dir").fn ".."
  elseif node.nodes ~= nil then
    require("nvim-tree.actions.root.change-dir").fn(lib.get_last_group_node(node).absolute_path)
  end
end

local function open_file(action, node)
  local path = node.absolute_path
  if node.link_to and not node.nodes then
    path = node.link_to
  end
  require("nvim-tree.actions.node.open-file").fn(action, path)
end

local function handle_tree_actions(action)
  local node = lib.get_node_at_cursor()
  if not node then
    return
  end

  local custom_function = M.custom_keypress_funcs[action]
  local defined_action = Actions[action]

  if type(custom_function) == "function" then
    return custom_function(node)
  elseif defined_action then
    return defined_action(node)
  end

  local is_parent = node.name == ".."

  if action == "preview" and is_parent then
    return
  end

  if action == "cd" or is_parent then
    return change_dir_action(node)
  end

  if node.nodes then
    lib.expand_or_collapse(node)
  else
    open_file(action, node)
  end
end

function M.dispatch(action)
  if view.is_help_ui() or action == "toggle_help" then
    handle_action_on_help_ui(action)
  elseif action == "live_filter" or action == "clear_live_filter" then
    handle_filter_actions(action)
  else
    handle_tree_actions(action)
  end
end

function M.setup(custom_keypress_funcs)
  M.custom_keypress_funcs = custom_keypress_funcs
end

return M
