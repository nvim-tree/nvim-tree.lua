local lib = require'nvim-tree.lib'
local config = require'nvim-tree.config'
local view = require'nvim-tree.view'

local M = {}

function M.setup(opts)
  require'nvim-tree.actions.system-open'.setup(opts.system_open)
  require'nvim-tree.actions.trash'.setup(opts.trash)
end

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
  close = function() M.close() end,
  preview = function(node)
    if node.entries ~= nil then
      if (node.name == '..') then
        return
      end
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

  local custom_function = view.View.custom_keypress_funcs[action]
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

return M
