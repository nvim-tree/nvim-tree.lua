local a = vim.api

local lib = require "nvim-tree.lib"
local log = require "nvim-tree.log"
local view = require "nvim-tree.view"
local util = require "nvim-tree.utils"
local nvim_tree_callback = require("nvim-tree.config").nvim_tree_callback

-- BEGIN_DEFAULT_MAPPINGS
local M = {
  mappings = {
    {
      key = { "<CR>", "o", "<2-LeftMouse>" },
      action = "edit",
      desc = "open a file or folder; root will cd to the above directory",
    },
    {
      key = "<C-e>",
      action = "edit_in_place",
      desc = "edit the file in place, effectively replacing the tree explorer",
    },
    {
      key = "O",
      action = "edit_no_picker",
      desc = "same as (edit) with no window picker",
    },
    {
      key = { "<C-]>", "<2-RightMouse>" },
      action = "cd",
      desc = "cd in the directory under the cursor",
    },
    {
      key = "<C-v>",
      action = "vsplit",
      desc = "open the file in a vertical split",
    },
    {
      key = "<C-x>",
      action = "split",
      desc = "open the file in a horizontal split",
    },
    {
      key = "<C-t>",
      action = "tabnew",
      desc = "open the file in a new tab",
    },
    {
      key = "<",
      action = "prev_sibling",
      desc = "navigate to the previous sibling of current file/directory",
    },
    {
      key = ">",
      action = "next_sibling",
      desc = "navigate to the next sibling of current file/directory",
    },
    {
      key = "P",
      action = "parent_node",
      desc = "move cursor to the parent directory",
    },
    {
      key = "<BS>",
      action = "close_node",
      desc = "close current opened directory or parent",
    },
    {
      key = "<Tab>",
      action = "preview",
      desc = "open the file as a preview (keeps the cursor in the tree)",
    },
    {
      key = "K",
      action = "first_sibling",
      desc = "navigate to the first sibling of current file/directory",
    },
    {
      key = "J",
      action = "last_sibling",
      desc = "navigate to the last sibling of current file/directory",
    },
    {
      key = "I",
      action = "toggle_git_ignored",
      desc = "toggle visibility of files/folders hidden via |git.ignore| option",
    },
    {
      key = "H",
      action = "toggle_dotfiles",
      desc = "toggle visibility of dotfiles via |filters.dotfiles| option",
    },
    {
      key = "U",
      action = "toggle_custom",
      desc = "toggle visibility of files/folders hidden via |filters.custom| option",
    },
    {
      key = "R",
      action = "refresh",
      desc = "refresh the tree",
    },
    {
      key = "a",
      action = "create",
      desc = "add a file; leaving a trailing `/` will add a directory",
    },
    {
      key = "d",
      action = "remove",
      desc = "delete a file (will prompt for confirmation)",
    },
    {
      key = "D",
      action = "trash",
      desc = "trash a file via |trash| option",
    },
    {
      key = "r",
      action = "rename",
      desc = "rename a file",
    },
    {
      key = "<C-r>",
      action = "full_rename",
      desc = "rename a file and omit the filename on input",
    },
    {
      key = "x",
      action = "cut",
      desc = "add/remove file/directory to cut clipboard",
    },
    {
      key = "c",
      action = "copy",
      desc = "add/remove file/directory to copy clipboard",
    },
    {
      key = "p",
      action = "paste",
      desc = "paste from clipboard; cut clipboard has precedence over copy; will prompt for confirmation",
    },
    {
      key = "y",
      action = "copy_name",
      desc = "copy name to system clipboard",
    },
    {
      key = "Y",
      action = "copy_path",
      desc = "copy relative path to system clipboard",
    },
    {
      key = "gy",
      action = "copy_absolute_path",
      desc = "copy absolute path to system clipboard",
    },
    {
      key = "[c",
      action = "prev_git_item",
      desc = "go to next git item",
    },
    {
      key = "]c",
      action = "next_git_item",
      desc = "go to prev git item",
    },
    {
      key = "-",
      action = "dir_up",
      desc = "navigate up to the parent directory of the current file/directory",
    },
    {
      key = "s",
      action = "system_open",
      desc = "open a file with default system application or a folder with default file manager, using |system_open| option",
    },
    {
      key = "f",
      action = "live_filter",
      desc = "live filter nodes dynamically based on regex matching.",
    },
    {
      key = "F",
      action = "clear_live_filter",
      desc = "clear live filter",
    },
    {
      key = "q",
      action = "close",
      desc = "close tree window",
    },
    {
      key = "W",
      action = "collapse_all",
      desc = "collapse the whole tree",
    },
    {
      key = "E",
      action = "expand_all",
      desc = "expand the whole tree, stopping after expanding |actions.expand_all.max_folder_discovery| folders; this might hang neovim for a while if running on a big folder",
    },
    {
      key = "S",
      action = "search_node",
      desc = "prompt the user to enter a path and then expands the tree to match the path",
    },
    {
      key = ".",
      action = "run_file_command",
      desc = "enter vim command mode with the file the cursor is on",
    },
    {
      key = "<C-k>",
      action = "toggle_file_info",
      desc = "toggle a popup with file infos about the file under the cursor",
    },
    {
      key = "g?",
      action = "toggle_help",
      desc = "toggle help",
    },
  },
  custom_keypress_funcs = {},
}
-- END_DEFAULT_MAPPINGS

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
  next_git_item = require("nvim-tree.actions.movements").find_git_item "next",
  next_sibling = require("nvim-tree.actions.movements").sibling(1),
  parent_node = require("nvim-tree.actions.movements").parent_node(false),
  paste = require("nvim-tree.actions.copy-paste").paste,
  prev_git_item = require("nvim-tree.actions.movements").find_git_item "prev",
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

function M.on_keypress(action)
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

function M.apply_mappings(bufnr)
  for _, b in pairs(M.mappings) do
    local mapping_rhs = b.cb or nvim_tree_callback(b.action)
    if type(b.key) == "table" then
      for _, key in pairs(b.key) do
        a.nvim_buf_set_keymap(bufnr, b.mode or "n", key, mapping_rhs, { noremap = true, silent = true, nowait = true })
      end
    elseif mapping_rhs then
      a.nvim_buf_set_keymap(bufnr, b.mode or "n", b.key, mapping_rhs, { noremap = true, silent = true, nowait = true })
    end
  end
end

local function merge_mappings(user_mappings)
  if #user_mappings == 0 then
    return M.mappings
  end

  local function is_empty(s)
    return s == ""
  end

  local user_keys = {}
  local removed_keys = {}
  -- remove default mappings if action is a empty string
  for _, map in pairs(user_mappings) do
    if type(map.key) == "table" then
      for _, key in pairs(map.key) do
        table.insert(user_keys, key)
        if is_empty(map.action) then
          table.insert(removed_keys, key)
        end
      end
    else
      table.insert(user_keys, map.key)
      if is_empty(map.action) then
        table.insert(removed_keys, map.key)
      end
    end

    if map.action and type(map.action_cb) == "function" then
      if not is_empty(map.action) then
        M.custom_keypress_funcs[map.action] = map.action_cb
      else
        util.warn "action can't be empty if action_cb provided"
      end
    end
  end

  local default_map = vim.tbl_filter(function(map)
    if type(map.key) == "table" then
      local filtered_keys = {}
      for _, key in pairs(map.key) do
        if not vim.tbl_contains(user_keys, key) and not vim.tbl_contains(removed_keys, key) then
          table.insert(filtered_keys, key)
        end
      end
      map.key = filtered_keys
      return not vim.tbl_isempty(map.key)
    else
      return not vim.tbl_contains(user_keys, map.key) and not vim.tbl_contains(removed_keys, map.key)
    end
  end, M.mappings)

  local user_map = vim.tbl_filter(function(map)
    return not is_empty(map.action)
  end, user_mappings)

  return vim.fn.extend(default_map, user_map)
end

local function copy_mappings(user_mappings)
  if #user_mappings == 0 then
    return M.mappings
  end

  for _, map in pairs(user_mappings) do
    if map.action and type(map.action_cb) == "function" then
      M.custom_keypress_funcs[map.action] = map.action_cb
    end
  end

  return user_mappings
end

local DEFAULT_MAPPING_CONFIG = {
  custom_only = false,
  list = {},
}

function M.setup(opts)
  require("nvim-tree.actions.system-open").setup(opts)
  require("nvim-tree.actions.trash").setup(opts)
  require("nvim-tree.actions.open-file").setup(opts)
  require("nvim-tree.actions.change-dir").setup(opts)
  require("nvim-tree.actions.create-file").setup(opts)
  require("nvim-tree.actions.rename-file").setup(opts)
  require("nvim-tree.actions.remove-file").setup(opts)
  require("nvim-tree.actions.copy-paste").setup(opts)
  require("nvim-tree.actions.expand-all").setup(opts)

  local user_map_config = (opts.view or {}).mappings or {}
  local options = vim.tbl_deep_extend("force", DEFAULT_MAPPING_CONFIG, user_map_config)
  if options.custom_only then
    M.mappings = copy_mappings(options.list)
  else
    M.mappings = merge_mappings(options.list)
  end

  log.line("config", "active mappings")
  log.raw("config", "%s\n", vim.inspect(M.mappings))
end

return M
