local a = vim.api
local uv = vim.loop

local lib = require'nvim-tree.lib'
local utils = require'nvim-tree.utils'

local M = {}

local clipboard = {
  move = {},
  copy = {}
}

local function do_copy(source, destination)
  local source_stats = uv.fs_stat(source)

  if source_stats and source_stats.type == 'file' then
    return uv.fs_copyfile(source, destination)
  end

  local handle = uv.fs_scandir(source)

  if type(handle) == 'string' then
    return false, handle
  end

  uv.fs_mkdir(destination, source_stats.mode)

  while true do
    local name, _ = uv.fs_scandir_next(handle)
    if not name then break end

    local new_name = utils.path_join({source, name})
    local new_destination = utils.path_join({destination, name})
    local success, msg = do_copy(new_name, new_destination)
    if not success then return success, msg end
  end

  return true
end

local function do_single_paste(source, dest, action_type, action_fn)
  local dest_stats = uv.fs_stat(dest)
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
      a.nvim_err_writeln('Could not '..action_type..' '..source..' - '..errmsg)
    end
  end
end

local function add_to_clipboard(node, clip)
  if node.name == '..' then return end

  for idx, entry in ipairs(clip) do
    if entry.absolute_path == node.absolute_path then
      table.remove(clip, idx)
      return a.nvim_out_write(node.absolute_path..' removed to clipboard.\n')
    end
  end
  table.insert(clip, node)
  a.nvim_out_write(node.absolute_path..' added to clipboard.\n')
end

function M.copy(node)
  add_to_clipboard(node, clipboard.copy)
end

function M.cut(node)
  add_to_clipboard(node, clipboard.move)
end

local function do_paste(node, action_type, action_fn)
  node = lib.get_last_group_node(node)
  if node.name == '..' then return end
  local clip = clipboard[action_type]
  if #clip == 0 then return end

  local destination = node.absolute_path
  local stats = uv.fs_stat(destination)
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

local function do_cut(source, destination)
  local success = uv.fs_rename(source, destination)
  if not success then
    return success
  end
  utils.rename_loaded_buffers(source, destination)
  return true
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

  return a.nvim_out_write(table.concat(content, '\n')..'\n')
end

local function copy_to_clipboard(content)
  vim.fn.setreg('+', content);
  vim.fn.setreg('"', content);
  return a.nvim_out_write(string.format('Copied %s to system clipboard! \n', content))
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
