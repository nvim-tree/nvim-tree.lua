local uv = vim.loop
local utils = require'nvim-tree.utils'

local M = {
  is_windows = vim.fn.has('win32') == 1
}

local function get_dir_git_status(parent_ignored, status, absolute_path)
  if parent_ignored then
    return '!!'
  end
  local dir_status = status.dirs and status.dirs[absolute_path]
  local file_status = status.files and status.files[absolute_path]
  return dir_status or file_status
end

function M.folder(cwd, name, status, parent_ignored)
  local absolute_path = utils.path_join({cwd, name})
  local handle = uv.fs_scandir(absolute_path)
  local has_children = handle and uv.fs_scandir_next(handle) ~= nil

  return {
    absolute_path = absolute_path,
    git_status = get_dir_git_status(parent_ignored, status, absolute_path),
    group_next = nil, -- If node is grouped, this points to the next child dir/link node
    has_children = has_children,
    name = name,
    nodes = {},
    open = false,
  }
end

local function is_executable(absolute_path, ext)
  if M.is_windows then
    return utils.is_windows_exe(ext)
  end
  return uv.fs_access(absolute_path, 'X')
end

function M.file(cwd, name, status, parent_ignored)
  local absolute_path = utils.path_join({cwd, name})
  local ext = string.match(name, ".?[^.]+%.(.*)") or ""

  return {
    absolute_path = absolute_path,
    executable = is_executable(absolute_path, ext),
    extension = ext,
    git_status = parent_ignored and '!!' or status.files and status.files[absolute_path],
    name = name,
  }
end

-- TODO-INFO: sometimes fs_realpath returns nil
-- I expect this be a bug in glibc, because it fails to retrieve the path for some
-- links (for instance libr2.so in /usr/lib) and thus even with a C program realpath fails
-- when it has no real reason to. Maybe there is a reason, but errno is definitely wrong.
-- So we need to check for link_to ~= nil when adding new links to the main tree
function M.link(cwd, name, status, parent_ignored)
  --- I dont know if this is needed, because in my understanding, there isnt hard links in windows, but just to be sure i changed it.
  local absolute_path = utils.path_join({ cwd, name })
  local link_to = uv.fs_realpath(absolute_path)
  local stat = uv.fs_stat(absolute_path)
  local open, nodes
  if (link_to ~= nil) and uv.fs_stat(link_to).type == 'directory' then
    open = false
    nodes = {}
  end

  local last_modified = 0
  if stat ~= nil then
    last_modified = stat.mtime.sec
  end

  return {
    absolute_path = absolute_path,
    git_status = parent_ignored and '!!' or status.files and status.files[absolute_path],
    group_next = nil,   -- If node is grouped, this points to the next child dir/link node
    last_modified = last_modified,
    link_to = link_to,
    name = name,
    nodes = nodes,
    open = open,
  }
end

return M
