local api = vim.api
local luv = vim.loop
local open_mode = luv.constants.O_CREAT + luv.constants.O_WRONLY + luv.constants.O_TRUNC

local M = {}

local function clear_prompt()
  vim.api.nvim_command('normal :esc<CR>')
end

local function refresh_tree()
  vim.api.nvim_command(":LuaTreeRefresh")
end

local function create_file(file)
  luv.fs_open(file, "w", open_mode, vim.schedule_wrap(function(err, fd)
    if err then
      api.nvim_err_writeln('Could not create file '..file)
    else
      -- FIXME: i don't know why but libuv keeps creating file with executable permissions
      -- this is why we need to chmod to default file permissions
      luv.fs_chmod(file, 420)
      luv.fs_close(fd)
      api.nvim_out_write('File '..file..' was properly created\n')
      refresh_tree()
    end
  end))
end

local function get_num_entries(iter)
  i = 0
  for _ in iter do
    i = i + 1
  end
  return i
end

function M.create(node)
  if node.name == '..' then return end
  
  local add_into
  if node.entries ~= nil then
    add_into = node.absolute_path..'/'
  else
    add_into = node.absolute_path:sub(0, -(#node.name + 1))
  end

  local ans = vim.fn.input('Create file '..add_into)
  clear_prompt()
  if not ans or #ans == 0 then return end

  if not ans:match('/') then
    return create_file(add_into..ans)
  end

  -- create a foler for each element until / and create a file when element is not ending with /
  -- if element is ending with / and it's the last element, we need to manually refresh
  local relpath = ''
  local idx = 0
  local num_entries = get_num_entries(ans:gmatch('[^/]+/?'))
  for path in ans:gmatch('[^/]+/?') do
    idx = idx + 1
    relpath = relpath..path
    if relpath:match('.*/$') then
      local success = luv.fs_mkdir(add_into..relpath, 493)
      if not success then
        api.nvim_err_writeln('Could not create folder '..add_into..relpath)
        return
      end
      if idx == num_entries then
        api.nvim_out_write('Folder '..add_into..relpath..' was properly created\n')
        refresh_tree()
      end
    else
      create_file(add_into..relpath)
    end
  end
end

local remove_ok = true

local function remove_callback(name, absolute_path)
  return function(err, success)
    if err ~= nil then
      api.nvim_err_writeln(err)
      remove_ok = false
    elseif not success then
      remove_ok = false
      api.nvim_err_writeln('Could not remove '..name)
    else
      api.nvim_out_write(name..' has been removed\n')
      for _, buf in pairs(api.nvim_list_bufs()) do
        if api.nvim_buf_get_name(buf) == absolute_path then
          api.nvim_command(':bd! '..buf)
        end
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

    local new_cwd = cwd..'/'..name
    if t == 'directory' then
      remove_dir(new_cwd)
    else
      luv.fs_unlink(new_cwd, vim.schedule_wrap(remove_callback(new_cwd, new_cwd)))
    end
    if not remove_ok then return end
  end

  luv.fs_rmdir(cwd, vim.schedule_wrap(remove_callback(cwd, cwd)))
end

function M.remove(node)
  if node.name == '..' then return end

  local ans = vim.fn.input("Remove " ..node.name.. " ? y/n: ")
  clear_prompt()
  if ans:match('^y') then
    remove_ok = true
    if node.entries ~= nil then
      remove_dir(node.absolute_path)
    else
      luv.fs_unlink(node.absolute_path, vim.schedule_wrap(
        remove_callback(node.name, node.absolute_path)
      ))
    end
    refresh_tree()
  end
end

local function rename_callback(node, new_name)
  return function(err, success)
    if err ~= nil then
      api.nvim_err_writeln(err)
    elseif not success then
      api.nvim_err_writeln('Could not rename '..node.absolute_path..' to '..new_name)
    else
      api.nvim_out_write(node.absolute_path..' ➜ '..new_name..'\n')
      for _, buf in pairs(api.nvim_list_bufs()) do
        if api.nvim_buf_get_name(buf) == node.absolute_path then
          api.nvim_buf_set_name(buf, new_name)
        end
      end
      refresh_tree()
    end
  end
end

function M.rename(node)
  if node.name == '..' then return end

  local ans = vim.fn.input("Rename " ..node.name.. " to ", node.absolute_path)
  clear_prompt()
  if not ans or #ans == 0 then return end

  luv.fs_rename(node.absolute_path, ans, vim.schedule_wrap(rename_callback(node, ans)))
end

return M
