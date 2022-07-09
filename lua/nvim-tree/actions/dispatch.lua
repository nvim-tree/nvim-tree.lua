local view = require "nvim-tree.view"
local lib = require "nvim-tree.lib"

local M = {}

local keypress_funcs = {
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
  live_filter = require("nvim-tree.live-filter").start_filtering,
  clear_live_filter = require("nvim-tree.live-filter").clear_filter,
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
  toggle_help = require("nvim-tree.actions.toggles").help,
  toggle_custom = require("nvim-tree.actions.toggles").custom,
  toggle_git_ignored = require("nvim-tree.actions.toggles").git_ignored,
  trash = require("nvim-tree.actions.trash").fn,
}

function M.dispatch(action)
  if view.is_help_ui() and action == "close" then
    action = "toggle_help"
  end
  if view.is_help_ui() and action ~= "toggle_help" then
    return
  end

  if action == "live_filter" or action == "clear_live_filter" then
    return keypress_funcs[action]()
  end

  local node = lib.get_node_at_cursor()
  if not node then
    return
  end

  local custom_function = M.custom_keypress_funcs[action]
  local default_function = keypress_funcs[action]

  if type(custom_function) == "function" then
    return custom_function(node)
  elseif default_function then
    return default_function(node)
  end

  if action == "preview" then
    if node.name == ".." then
      return
    end
    if not node.nodes then
      return require("nvim-tree.actions.open-file").fn("preview", node.absolute_path)
    end
  elseif node.name == ".." then
    return require("nvim-tree.actions.change-dir").fn ".."
  elseif action == "cd" then
    if node.nodes ~= nil then
      require("nvim-tree.actions.change-dir").fn(lib.get_last_group_node(node).absolute_path)
    end
    return
  end

  if node.link_to and not node.nodes then
    require("nvim-tree.actions.open-file").fn(action, node.link_to)
  elseif node.nodes ~= nil then
    lib.expand_or_collapse(node)
  else
    require("nvim-tree.actions.open-file").fn(action, node.absolute_path)
  end
end

function M.setup(custom_keypress_funcs)
  M.custom_keypress_funcs = custom_keypress_funcs
end

return M
