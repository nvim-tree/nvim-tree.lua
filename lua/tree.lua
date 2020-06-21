local luv = vim.loop
local lib = require'lib.lib'
local colors = require'lib.colors'
local renderer = require'lib.renderer'
local fs = require'lib.fs'
local utils = require'lib.utils'
local api = vim.api

local M = {}

function M.toggle()
  if lib.win_open() then
    lib.close()
  else
    lib.open()
  end
end

function M.close()
  if lib.win_open() then
    lib.close()
  end
end

function M.open()
  if not lib.win_open() then
    lib.open()
  end
end

function M.on_keypress(mode)
  local node = lib.get_node_at_cursor()
  if not node then return end

  if mode == 'create' then
    return fs.create(node)
  elseif mode == 'remove' then
    return fs.remove(node)
  elseif mode == 'rename' then
    return fs.rename(node)
  end

  if mode == 'preview' then
    if node.entries ~= nil or node.name == '..' then return end
    return lib.open_file(mode, node.absolute_path)
  end

  if node.name == ".." then
    return lib.change_dir("..")
  elseif mode == "cd" and node.entries ~= nil then
    return lib.change_dir(node.absolute_path)
  elseif mode == "cd" then
    return
  end

  if node.link_to then
    local stat = luv.fs_stat(node.link_to)
    -- TODO: potentially CD here
    if stat.type == 'directory' then return end
    lib.open_file(mode, node.link_to)
  elseif node.entries ~= nil then
    lib.unroll_dir(node)
  else
    lib.open_file(mode, node.absolute_path)
  end
end

function M.refresh()
  lib.refresh_tree()
end

function M.on_enter()
  local bufnr = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(bufnr)

  local stats = luv.fs_stat(bufname)
  local is_dir = stats and stats.type == 'directory'
  if is_dir then
    api.nvim_command('cd '..bufname)
  end
  local should_open = vim.g.lua_tree_auto_open == 1 and (bufname == '' or is_dir)
  colors.setup()
  lib.init(should_open, should_open)
end

local function is_file_readable(fname)
  local stat = luv.fs_stat(fname)
  if not stat or not stat.type == 'file' or not luv.fs_access(fname, 'R') then return false end
  return true
end

function M.find_file()
  local bufname = api.nvim_buf_get_name(api.nvim_get_current_buf())
  if not is_file_readable(bufname) then return end

  lib.set_index_and_redraw(bufname)
end

function M.on_leave()
  vim.defer_fn(function()
    if #api.nvim_list_wins() == 1 and lib.win_open() then
      api.nvim_command(':qa!')
    end
  end, 50)
end

local function update_root_dir()
  local bufname = api.nvim_buf_get_name(api.nvim_get_current_buf())
  if not is_file_readable(bufname) or not lib.Tree.cwd then return end

  -- this logic is a hack
  -- depending on vim-rooter or autochdir, it would not behave the same way when those two are not enabled
  -- until i implement multiple workspaces/project, it should stay like this
  if bufname:match(utils.path_to_matching_str(lib.Tree.cwd)) then
    return
  end
  local new_cwd = luv.cwd()
  if lib.Tree.cwd == new_cwd then return end

  lib.change_dir(new_cwd)
end

function M.buf_enter()
  update_root_dir()
  if vim.g.lua_tree_follow == 1 then
    M.find_file()
  end
end

function M.reset_highlight()
  colors.setup()
  renderer.render_hl(lib.Tree.bufnr)
end

function M.xdg_open()
  local node = lib.get_node_at_cursor()
  -- TODO: this should open symlink targets
  if not node or node.entries or node.link_to then return end

  local cmd
  if vim.fn.has('unix') == 1 then
    cmd = 'xdg-open'
  else
    cmd = 'open'
  end

  vim.loop.spawn(cmd, {args={node.absolute_path}}, vim.schedule_wrap(function(code)
    if code ~= 0 then
      api.nvim_err_writeln("Could not open "..node.absolute_path)
    end
  end))
end

return M
