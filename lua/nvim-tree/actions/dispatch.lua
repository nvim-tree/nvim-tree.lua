local view = require "nvim-tree.view"
local lib = require "nvim-tree.lib"

local M = {}

local Actions = {
  close = view.close,
  close_node = require("nvim-tree.actions.movements").parent_node(true),
  collapse_all = require("nvim-tree.actions.collapse-all").fn,
  expand_all = require("nvim-tree.actions.expand-all").fn,
  copy_absolute_path = require("nvim-tree.actions.copy-paste").copy_absolute_path,
  copy_name = require("nvim-tree.actions.copy-paste").copy_filename,
  copy_path = require("nvim-tree.actions.copy-paste").copy_path,
  copy = require("nvim-tree.actions.copy-paste").copy,
  create = require("nvim-tree.actions.create-file").fn,
  cut = require("nvim-tree.actions.copy-paste").cut,
  dir_up = require("nvim-tree.actions.dir-up").fn,
  first_sibling = require("nvim-tree.actions.movements").sibling(-math.huge),
  full_rename = require("nvim-tree.actions.rename-file").fn(true),
  last_sibling = require("nvim-tree.actions.movements").sibling(math.huge),
  next_diag_item = require("nvim-tree.actions.movements").find_item("next", "diag"),
  next_git_item = require("nvim-tree.actions.movements").find_item("next", "git"),
  next_sibling = require("nvim-tree.actions.movements").sibling(1),
  parent_node = require("nvim-tree.actions.movements").parent_node(false),
  paste = require("nvim-tree.actions.copy-paste").paste,
  prev_diag_item = require("nvim-tree.actions.movements").find_item("prev", "diag"),
  prev_git_item = require("nvim-tree.actions.movements").find_item("prev", "git"),
  prev_sibling = require("nvim-tree.actions.movements").sibling(-1),
  refresh = require("nvim-tree.actions.reloaders").reload_explorer,
  remove = require("nvim-tree.actions.remove-file").fn,
  rename = require("nvim-tree.actions.rename-file").fn(false),
  run_file_command = require("nvim-tree.actions.run-command").run_file_command,
  search_node = require("nvim-tree.actions.search-node").fn,
  toggle_file_info = require("nvim-tree.actions.file-popup").toggle_file_info,
  system_open = require("nvim-tree.actions.system-open").fn,
  toggle_dotfiles = require("nvim-tree.actions.toggles").dotfiles,
  toggle_custom = require("nvim-tree.actions.toggles").custom,
  toggle_git_ignored = require("nvim-tree.actions.toggles").git_ignored,
  trash = require("nvim-tree.actions.trash").fn,
}

local function handle_action_on_help_ui(action)
  if action == "close" or action == "toggle_help" then
    require("nvim-tree.actions.toggles").help()
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
    require("nvim-tree.actions.change-dir").fn ".."
  elseif node.nodes ~= nil then
    require("nvim-tree.actions.change-dir").fn(lib.get_last_group_node(node).absolute_path)
  end
end

local function open_file(action, node)
  local path = node.absolute_path
  if node.link_to and not node.nodes then
    path = node.link_to
  end
  require("nvim-tree.actions.open-file").fn(action, path)
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
  elseif action:match "live" ~= nil then
    handle_filter_actions(action)
  else
    handle_tree_actions(action)
  end
end

function M.setup(custom_keypress_funcs)
  M.custom_keypress_funcs = custom_keypress_funcs
end

return M
