local a = vim.api

local lib = require'nvim-tree.lib'
local config = require'nvim-tree.config'
local view = require'nvim-tree.view'
local nvim_tree_callback = require'nvim-tree.config'.nvim_tree_callback

local M = {
  mappings = {
    { key = {"<CR>", "o", "<2-LeftMouse>"}, action = "edit" },
    { key = {"O"},                          action = "edit_no_picker" },
    { key = {"<2-RightMouse>", "<C-]>"},    action = "cd" },
    { key = "<C-v>",                        action = "vsplit" },
    { key = "<C-x>",                        action = "split"},
    { key = "<C-t>",                        action = "tabnew" },
    { key = "<",                            action = "prev_sibling" },
    { key = ">",                            action = "next_sibling" },
    { key = "P",                            action = "parent_node" },
    { key = "<BS>",                         action = "close_node"},
    { key = "<Tab>",                        action = "preview" },
    { key = "K",                            action = "first_sibling" },
    { key = "J",                            action = "last_sibling" },
    { key = "I",                            action = "toggle_ignored" },
    { key = "H",                            action = "toggle_dotfiles" },
    { key = "R",                            action = "refresh" },
    { key = "a",                            action = "create" },
    { key = "d",                            action = "remove" },
    { key = "D",                            action = "trash"},
    { key = "r",                            action = "rename" },
    { key = "<C-r>",                        action = "full_rename" },
    { key = "x",                            action = "cut" },
    { key = "c",                            action = "copy"},
    { key = "p",                            action = "paste" },
    { key = "y",                            action = "copy_name" },
    { key = "Y",                            action = "copy_path" },
    { key = "gy",                           action = "copy_absolute_path" },
    { key = "[c",                           action = "prev_git_item" },
    { key = "]c",                           action = "next_git_item" },
    { key = "-",                            action = "dir_up" },
    { key = "s",                            action = "system_open" },
    { key = "q",                            action = "close"},
    { key = "g?",                           action = "toggle_help" }
  },
  custom_keypress_funcs = {},
}

local function go_to(mode)
  local icon_state = config.get_icon_state()
  local flags = mode == 'prev_git_item' and 'b' or ''
  local icons = table.concat(vim.tbl_values(icon_state.icons.git_icons), '\\|')
  return function()
    return icon_state.show_git_icon and vim.fn.search(icons, flags)
  end
end

local keypress_funcs = {
  create = require'nvim-tree.actions.create-file'.fn,
  remove = require'nvim-tree.actions.remove-file'.fn,
  rename = require'nvim-tree.actions.rename-file'.fn(false),
  full_rename = require'nvim-tree.actions.rename-file'.fn(true),
  copy = require'nvim-tree.actions.copy-paste'.copy,
  copy_name = require'nvim-tree.actions.copy-paste'.copy_filename,
  copy_path = require'nvim-tree.actions.copy-paste'.copy_path,
  copy_absolute_path = require'nvim-tree.actions.copy-paste'.copy_absolute_path,
  cut = require'nvim-tree.actions.copy-paste'.cut,
  paste = require'nvim-tree.actions.copy-paste'.paste,
  close_node = lib.close_node,
  parent_node = lib.parent_node,
  toggle_ignored = lib.toggle_ignored,
  toggle_dotfiles = lib.toggle_dotfiles,
  toggle_help = lib.toggle_help,
  refresh = lib.refresh_tree,
  first_sibling = function(node) lib.sibling(node, -math.huge) end,
  last_sibling = function(node) lib.sibling(node, math.huge) end,
  prev_sibling = function(node) lib.sibling(node, -1) end,
  next_sibling = function(node) lib.sibling(node, 1) end,
  prev_git_item = go_to('prev_git_item'),
  next_git_item = go_to('next_git_item'),
  dir_up = lib.dir_up,
  close = function() require'nvim-tree'.close() end,
  preview = function(node)
    if node.name == '..' then
      return
    end
    if node.entries ~= nil then
      return lib.expand_or_collapse(node)
    end
    return require'nvim-tree.actions.open-file'.fn('preview', node.absolute_path)
  end,
  system_open = require'nvim-tree.actions.system-open'.fn,
  trash = require'nvim-tree.actions.trash'.fn,
}

function M.on_keypress(action)
  if view.is_help_ui() and action ~= 'toggle_help' then return end
  local node = lib.get_node_at_cursor()
  if not node then return end

  local custom_function = M.custom_keypress_funcs[action]
  local default_function = keypress_funcs[action]

  if type(custom_function) == 'function' then
    return custom_function(node)
  elseif default_function then
    return default_function(node)
  end

  if node.name == ".." then
    return lib.change_dir("..")
  elseif action == "cd" and node.entries ~= nil then
    return lib.change_dir(lib.get_last_group_node(node).absolute_path)
  elseif action == "cd" then
    return
  end

  if node.link_to and not node.entries then
    require'nvim-tree.actions.open-file'.fn(action, node.link_to)
  elseif node.entries ~= nil then
    lib.expand_or_collapse(node)
  else
    require'nvim-tree.actions.open-file'.fn(action, node.absolute_path)
  end
end

function M.apply_mappings(bufnr)
  for _, b in pairs(M.mappings) do
    local mapping_rhs = b.cb or nvim_tree_callback(b.action)
    if type(b.key) == "table" then
      for _, key in pairs(b.key) do
        a.nvim_buf_set_keymap(bufnr, b.mode or 'n', key, mapping_rhs, { noremap = true, silent = true, nowait = true })
      end
    elseif mapping_rhs then
      a.nvim_buf_set_keymap(bufnr, b.mode or 'n', b.key, mapping_rhs, { noremap = true, silent = true, nowait = true })
    end
  end
end

local function merge_mappings(user_mappings)
  if #user_mappings == 0 then
    return M.mappings
  end

  local user_keys = {}
  for _, map in pairs(user_mappings) do
    if type(map.key) == "table" then
      for _, key in pairs(map.key) do
        table.insert(user_keys, key)
      end
    else
       table.insert(user_keys, map.key)
    end
    if map.action and type(map.action_cb) == "function" then
      M.custom_keypress_funcs[map.action] = map.action_cb
    end
  end

  local mappings = vim.tbl_filter(function(map)
    return not vim.tbl_contains(user_keys, map.key)
  end, M.mappings)

  return vim.fn.extend(mappings, user_mappings)
end

local DEFAULT_MAPPING_CONFIG = {
  custom_only = false,
  list = {}
}

function M.setup(opts)
  require'nvim-tree.actions.system-open'.setup(opts.system_open)
  require'nvim-tree.actions.trash'.setup(opts.trash)

  local user_map_config = (opts.view or {}).mappings or {}
  local options = vim.tbl_deep_extend('force', DEFAULT_MAPPING_CONFIG, user_map_config)
  if options.custom_only then
    M.mappings = options.list
  else
    M.mappings = merge_mappings(options.list)
  end
end

return M
