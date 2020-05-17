local api = vim.api

local fs_update = require 'lib/fs_update'
local create_file = fs_update.create_file
local rename_file = fs_update.rename_file
local remove_file = fs_update.remove_file

local fs = require 'lib/fs'
local check_dir_access = fs.check_dir_access
local is_dir = fs.is_dir
local get_cwd = fs.get_cwd

local state = require 'lib/state'
local get_tree = state.get_tree
local init_tree = state.init_tree
local open_dir = state.open_dir
local refresh_tree = state.refresh_tree
local set_root_path = state.set_root_path
local find_file = state.find_file

local winutils = require 'lib/winutils'
local update_view = winutils.update_view
local is_win_open = winutils.is_win_open
local close = winutils.close
local open = winutils.open
local set_mappings = winutils.set_mappings
local get_win = winutils.get_win

local git = require 'lib/git'
local refresh_git = git.refresh_git
local force_refresh_git = git.force_refresh_git

local colors = require 'lib/colors'
colors.init_colors()

local M = {}

M.replace_tree = winutils.replace_tree

init_tree()

function M.toggle()
  if is_win_open() == true then
    local wins = api.nvim_list_wins()
    if #wins > 1 then close() end
  else
    open()
    update_view()
    set_mappings()
  end
end

local MOVE_TO = 'l'
if api.nvim_call_function('exists', { 'g:lua_tree_side' }) == 1 then
  if api.nvim_get_var('lua_tree_side') == 'right' then
    MOVE_TO = 'h'
  end
end

local function create_new_buf(open_type, bufname)
  if open_type == 'edit' or open_type == 'split' then
    api.nvim_command('wincmd '..MOVE_TO..' | '..open_type..' '..bufname)
  elseif open_type == 'vsplit' then
    local windows = api.nvim_list_wins();
    api.nvim_command(#windows..'wincmd '..MOVE_TO..' | vsplit '..bufname)
  elseif open_type == 'tabnew' then
    api.nvim_command('tabnew '..bufname)
  end
end

function M.open_file(open_type)
  local tree_index = api.nvim_win_get_cursor(0)[1]
  local tree = get_tree()
  local node = tree[tree_index]

  if node.name == '..' then
    api.nvim_command('cd '..node.path..'/..')

    local new_path = get_cwd()
    if new_path ~= '/' then
      new_path = new_path .. '/'
    end

    set_root_path(new_path)
    force_refresh_git()
    init_tree(new_path)
    update_view()

  elseif open_type == 'chdir' then
    if node.dir == false or check_dir_access(node.path .. node.name) == false then return end

    api.nvim_command('cd ' .. node.path .. node.name)
    local new_path = get_cwd() .. '/'
    set_root_path(new_path)
    force_refresh_git()
    init_tree(new_path)
    update_view()

  elseif node.link == true then
    local link_to_dir = is_dir(node.linkto)
    if link_to_dir == true and check_dir_access(node.linkto) == false then return end

    if link_to_dir == true then
      api.nvim_command('cd ' .. node.linkto)
      local new_path = get_cwd() .. '/'
      set_root_path(new_path)
      force_refresh_git()
      init_tree(new_path)
      update_view()
    else
      create_new_buf(open_type, node.link_to);
    end

  elseif node.dir == true then
    if check_dir_access(node.path .. node.name) == false then return end
    open_dir(tree_index)
    update_view(true)
  else
    create_new_buf(open_type, node.path .. node.name);
  end
end

function M.edit_file(edit_type)
  local tree = get_tree()
  local tree_index = api.nvim_win_get_cursor(0)[1]
  local node = tree[tree_index]

  if edit_type == 'create' then
    if node.dir == true then
      create_file(node.path .. node.name .. '/')
    else
      create_file(node.path)
    end
  elseif edit_type == 'remove' then
    remove_file(node.name, node.path)
  elseif edit_type == 'rename' then
    rename_file(node.name, node.path)
  end
end

function M.refresh()
  if refresh_git() == true then
    refresh_tree()
    update_view()
  end
end

function M.check_windows_and_close()
  local wins = api.nvim_list_wins()

  if #wins == 1 and is_win_open() then
    api.nvim_command('q!')
  end
end

function M.check_buffer_and_open()
  local bufname = api.nvim_buf_get_name(0)
  if bufname == '' then
    M.toggle()
  elseif is_dir(bufname) then
    api.nvim_command('cd ' .. bufname)

    local new_path = get_cwd()
    if new_path ~= '/' then
      new_path = new_path .. '/'
    end
    set_root_path(new_path)
    init_tree()

    M.toggle()
  end
end

function M.find()
  local line = find_file(api.nvim_buf_get_name(0))
  if not line then return end

  update_view()

  local win = get_win()
  if win then
    api.nvim_win_set_cursor(win, { line, 0 })
  end

end

function M.reset_highlight()
  colors.init_colors()
  update_view()
end

return M
