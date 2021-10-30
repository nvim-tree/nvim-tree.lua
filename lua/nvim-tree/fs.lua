local api = vim.api
local luv = vim.loop

local utils = require'nvim-tree.utils'
local view = require'nvim-tree.view'
local lib = require'nvim-tree.lib'
local events = require'nvim-tree.events'
local M = {}
local clipboard = {
  move = {},
  copy = {}
}

local function focus_file(file)
  local _, i = utils.find_node(
    lib.Tree.entries,
    function(node) return node.absolute_path == file end
  )
  view.set_cursor({i+1, 1})
end

local function create_file(file)
  if luv.fs_access(file, "r") ~= false then
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
  if not ans or #ans == 0 or luv.fs_access(ans, 'r') then return end

  -- create a folder for each path element if the folder does not exist
  -- if the answer ends with a /, create a file for the last entry
  local is_last_path_file = not ans:match(utils.path_separator..'$')
  local path_to_create = ''
  local idx = 0

  local num_entries = get_num_entries(utils.path_split(utils.path_remove_trailing(ans)))
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
    elseif not luv.fs_access(path_to_create, "r") then
      local success = luv.fs_mkdir(path_to_create, 493)
      if not success then
        api.nvim_err_writeln('Could not create folder '..path_to_create)
        break
      end
    end
  end
  api.nvim_out_write(ans..' was properly created\n')
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

local function rename_loaded_buffers(old_name, new_name)
  for _, buf in pairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(buf) then
      if api.nvim_buf_get_name(buf) == old_name then
        api.nvim_buf_set_name(buf, new_name)
        -- to avoid the 'overwrite existing file' error message on write
        vim.api.nvim_buf_call(buf, function() vim.cmd("silent! w!") end)
      end
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

local function do_copy(source, destination)
  local source_stats = luv.fs_stat(source)

  if source_stats and source_stats.type == 'file' then
    return luv.fs_copyfile(source, destination)
  end

  local handle = luv.fs_scandir(source)

  if type(handle) == 'string' then
    return false, handle
  end

  luv.fs_mkdir(destination, source_stats.mode)

  while true do
    local name, _ = luv.fs_scandir_next(handle)
    if not name then break end

    local new_name = utils.path_join({source, name})
    local new_destination = utils.path_join({destination, name})
    local success, msg = do_copy(new_name, new_destination)
    if not success then return success, msg end
  end

  return true
end

local function do_cut(source, destination)
  local success = luv.fs_rename(source, destination)
  if not success then
    return success
  end
  rename_loaded_buffers(source, destination)
  return true
end

local function do_single_paste(source, dest, action_type, action_fn)
  local dest_stats = luv.fs_stat(dest)
  local should_process = true
  local should_rename = false

  if dest_stats then
    print(dest..' already exists. Overwrite? y/n/r(ename)')
    local ans = utils.get_user_input_char()
    utils.clear_prompt()
    should_process = ans:match('^y')
    should_rename = ans:match('^r')
  end

  if should_rename then
    local new_dest = vim.fn.input('New name: ', dest)
    return do_single_paste(source, new_dest, action_type, action_fn)
  end

  if should_process then
    local success, errmsg = action_fn(source, dest)
    if not success then
      api.nvim_err_writeln('Could not '..action_type..' '..source..' - '..errmsg)
    end
  end
end

local function do_paste(node, action_type, action_fn)
  node = lib.get_last_group_node(node)
  if node.name == '..' then return end
  local clip = clipboard[action_type]
  if #clip == 0 then return end

  local destination = node.absolute_path
  local stats = luv.fs_stat(destination)
  local is_dir = stats and stats.type == 'directory'

  if not is_dir then
    destination = vim.fn.fnamemodify(destination, ':p:h')
  elseif not node.open then
    destination = vim.fn.fnamemodify(destination, ':p:h:h')
  end

  for _, entry in ipairs(clip) do
    local dest = utils.path_join({destination, entry.name })
    do_single_paste(entry.absolute_path, dest, action_type, action_fn)
  end

  clipboard[action_type] = {}
  return lib.refresh_tree()
end

local function add_to_clipboard(node, clip)
  if node.name == '..' then return end

  for idx, entry in ipairs(clip) do
    if entry.absolute_path == node.absolute_path then
      table.remove(clip, idx)
      return api.nvim_out_write(node.absolute_path..' removed to clipboard.\n')
    end
  end
  table.insert(clip, node)
  api.nvim_out_write(node.absolute_path..' added to clipboard.\n')
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
    if luv.fs_access(new_name, 'R') then
      utils.warn("Cannot rename: file already exists")
      return
    end

    local success = luv.fs_rename(node.absolute_path, new_name)
    if not success then
      return api.nvim_err_writeln('Could not rename '..node.absolute_path..' to '..new_name)
    end
    api.nvim_out_write(node.absolute_path..' ➜ '..new_name..'\n')
    rename_loaded_buffers(node.absolute_path, new_name)
    events._dispatch_node_renamed(abs_path, new_name)
    lib.refresh_tree()
  end
end

function M.copy(node)
  add_to_clipboard(node, clipboard.copy)
end

function M.cut(node)
  add_to_clipboard(node, clipboard.move)
end

function M.paste(node)
  if clipboard.move[1] ~= nil then
    return do_paste(node, 'move', do_cut)
  end

  return do_paste(node, 'copy', do_copy)
end

function M.print_clipboard()
  local content = {}
  if #clipboard.move > 0 then
    table.insert(content, 'Cut')
    for _, item in pairs(clipboard.move) do
      table.insert(content, ' * '..item.absolute_path)
    end
  end
  if #clipboard.copy > 0 then
    table.insert(content, 'Copy')
    for _, item in pairs(clipboard.copy) do
      table.insert(content, ' * '..item.absolute_path)
    end
  end

  return api.nvim_out_write(table.concat(content, '\n')..'\n')
end

local function copy_to_clipboard(content)
  vim.fn.setreg('+', content);
  vim.fn.setreg('"', content);
  return api.nvim_out_write(string.format('Copied %s to system clipboard! \n', content))
end

function M.copy_filename(node)
  return copy_to_clipboard(node.name)
end

function M.copy_path(node)
  local absolute_path = node.absolute_path
  local relative_path = utils.path_relative(absolute_path, lib.Tree.cwd)
  local content = node.entries ~= nil and utils.path_add_trailing(relative_path) or relative_path
  return copy_to_clipboard(content)
end

function M.copy_absolute_path(node)
  local absolute_path = node.absolute_path
  local content = node.entries ~= nil and utils.path_add_trailing(absolute_path) or absolute_path
  return copy_to_clipboard(content)
end

return M
