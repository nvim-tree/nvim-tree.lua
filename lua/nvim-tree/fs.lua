local api = vim.api
local luv = vim.loop

local utils = require'nvim-tree.utils'
local lib = require'nvim-tree.lib'
local events = require'nvim-tree.events'

local M = {}

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
