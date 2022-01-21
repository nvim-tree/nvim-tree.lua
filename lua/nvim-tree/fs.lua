local api = vim.api
local luv = vim.loop

local utils = require'nvim-tree.utils'
local view = require'nvim-tree.view'
local lib = require'nvim-tree.lib'
local events = require'nvim-tree.events'

local M = {}

local function focus_file(file)
  local _, i = utils.find_node(
    lib.Tree.entries,
    function(node) return node.absolute_path == file end
  )
  view.set_cursor({i+1, 1})
end

local function create_file(file)
  if utils.file_exists(file) then
    print(file..' already exists. Overwrite? y/n')
    local ans = utils.get_user_input_char()
    utils.clear_prompt()
    if ans ~= "y" then
      return
    end
  end
  luv.fs_open(file, "w", 420, vim.schedule_wrap(function(err, fd)
    if err then
      api.nvim_err_writeln('Couldn\'t create file '..file)
    else
      luv.fs_close(fd)
      events._dispatch_file_created(file)
      lib.refresh_tree()
      focus_file(file)
    end
  end))
end

local function get_num_entries(iter)
  local i = 0
  for _ in iter do
    i = i + 1
  end
  return i
end

function M.create(node)
  node = lib.get_last_group_node(node)
  if node.name == '..' then
    node = {
      absolute_path = lib.Tree.cwd,
      entries = lib.Tree.entries,
      open = true,
    }
  end

  local node_is_open = vim.g.nvim_tree_create_in_closed_folder == 1 or node.open

  local add_into
  if node.entries ~= nil and node_is_open then
    add_into = utils.path_add_trailing(node.absolute_path)
  else
    add_into = node.absolute_path:sub(0, -(#(node.name or '') + 1))
  end

  local ans = vim.fn.input('Create file ', add_into)
  utils.clear_prompt()
  if not ans or #ans == 0 or utils.file_exists(ans) then return end

  -- create a folder for each path element if the folder does not exist
  -- if the answer ends with a /, create a file for the last entry
  local is_last_path_file = not ans:match(utils.path_separator..'$')
  local path_to_create = ''
  local idx = 0

  local num_entries = get_num_entries(utils.path_split(utils.path_remove_trailing(ans)))
  local is_error = false
  for path in utils.path_split(ans) do
    idx = idx + 1
    local p = utils.path_remove_trailing(path)
    if #path_to_create == 0 and vim.fn.has('win32') == 1 then
      path_to_create = utils.path_join({p, path_to_create})
    else
      path_to_create = utils.path_join({path_to_create, p})
    end
    if is_last_path_file and idx == num_entries then
      create_file(path_to_create)
    elseif not utils.file_exists(path_to_create) then
      local success = luv.fs_mkdir(path_to_create, 493)
      if not success then
        api.nvim_err_writeln('Could not create folder '..path_to_create)
        is_error = true
        break
      end
    end
  end
  if not is_error then
    api.nvim_out_write(ans..' was properly created\n')
  end
  events._dispatch_folder_created(ans)
  lib.refresh_tree()
  focus_file(ans)
end

local function clear_buffer(absolute_path)
  local bufs = vim.fn.getbufinfo({bufloaded = 1, buflisted = 1})
  for _, buf in pairs(bufs) do
    if buf.name == absolute_path then
      if buf.hidden == 0 and #bufs > 1 then
        local winnr = api.nvim_get_current_win()
        api.nvim_set_current_win(buf.windows[1])
        vim.cmd(':bn')
        api.nvim_set_current_win(winnr)
      end
      vim.api.nvim_buf_delete(buf.bufnr, {})
      if buf.windows[1] then
        vim.api.nvim_win_close(buf.windows[1], true)
      end
      return
    end
  end
end

local function remove_dir(cwd)
  local handle = luv.fs_scandir(cwd)
  if type(handle) == 'string' then
    return api.nvim_err_writeln(handle)
  end

  while true do
    local name, t = luv.fs_scandir_next(handle)
    if not name then break end

    local new_cwd = utils.path_join({cwd, name})
    if t == 'directory' then
      local success = remove_dir(new_cwd)
      if not success then return false end
    else
      local success = luv.fs_unlink(new_cwd)
      if not success then return false end
      clear_buffer(new_cwd)
    end
  end

  return luv.fs_rmdir(cwd)
end


function M.remove(node)
  if node.name == '..' then return end

  print("Remove " ..node.name.. " ? y/n")
  local ans = utils.get_user_input_char()
  utils.clear_prompt()
  if ans:match('^y') then
    if node.entries ~= nil and not node.link_to then
      local success = remove_dir(node.absolute_path)
      if not success then
        return api.nvim_err_writeln('Could not remove '..node.name)
      end
      events._dispatch_folder_removed(node.absolute_path)
    else
      local success = luv.fs_unlink(node.absolute_path)
      if not success then
        return api.nvim_err_writeln('Could not remove '..node.name)
      end
      events._dispatch_file_removed(node.absolute_path)
      clear_buffer(node.absolute_path)
    end
    lib.refresh_tree()
  end
end

function M.rename(with_sub)
  return function(node)
    node = lib.get_last_group_node(node)
    if node.name == '..' then return end

    local namelen = node.name:len()
    local abs_path = with_sub and node.absolute_path:sub(0, namelen * (-1) -1) or node.absolute_path
    local new_name = vim.fn.input("Rename " ..node.name.. " to ", abs_path)
    utils.clear_prompt()
    if not new_name or #new_name == 0 then
      return
    end
    if utils.file_exists(new_name) then
      utils.warn("Cannot rename: file already exists")
      return
    end

    local success = luv.fs_rename(node.absolute_path, new_name)
    if not success then
      return api.nvim_err_writeln('Could not rename '..node.absolute_path..' to '..new_name)
    end
    api.nvim_out_write(node.absolute_path..' ➜ '..new_name..'\n')
    utils.rename_loaded_buffers(node.absolute_path, new_name)
    events._dispatch_node_renamed(abs_path, new_name)
    lib.refresh_tree()
  end
end

return M
