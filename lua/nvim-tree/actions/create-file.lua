local a = vim.api
local uv = vim.loop

local utils = require'nvim-tree.utils'
local events = require'nvim-tree.events'
local lib = require'nvim-tree.lib'

local M = {}

local function focus_file(file)
  local _, i = utils.find_node(
    lib.Tree.entries,
    function(node) return node.absolute_path == file end
  )
  require'nvim-tree.view'.set_cursor({i+1, 1})
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
  uv.fs_open(file, "w", 420, vim.schedule_wrap(function(err, fd)
    if err then
      a.nvim_err_writeln('Couldn\'t create file '..file)
    else
      uv.fs_close(fd)
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

function M.fn(node)
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
      local success = uv.fs_mkdir(path_to_create, 493)
      if not success then
        a.nvim_err_writeln('Could not create folder '..path_to_create)
        is_error = true
        break
      end
    end
  end
  if not is_error then
    a.nvim_out_write(ans..' was properly created\n')
  end
  events._dispatch_folder_created(ans)
  lib.refresh_tree()
  focus_file(ans)
end

return M
