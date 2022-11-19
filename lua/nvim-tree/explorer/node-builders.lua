local utils = require "nvim-tree.utils"
local watch = require "nvim-tree.explorer.watch"

local M = {
  is_windows = vim.fn.has "win32" == 1,
  is_wsl = vim.fn.has "wsl" == 1,
}

function M.folder(parent, absolute_path, name)
  local handle = vim.loop.fs_scandir(absolute_path)
  local has_children = handle and vim.loop.fs_scandir_next(handle) ~= nil

  local node = {
    type = "directory",
    absolute_path = absolute_path,
    fs_stat = vim.loop.fs_stat(absolute_path),
    group_next = nil, -- If node is grouped, this points to the next child dir/link node
    has_children = has_children,
    name = name,
    nodes = {},
    open = false,
    parent = parent,
  }

  node.watcher = watch.create_watcher(node)

  return node
end

function M.is_executable(parent, absolute_path, ext)
  if M.is_windows then
    return utils.is_windows_exe(ext)
  elseif M.is_wsl then
    if parent.is_wsl_windows_fs_path == nil then
      -- Evaluate lazily when needed and do so only once for each parent
      -- as 'wslpath' calls can get expensive in highly populated directories.
      parent.is_wsl_windows_fs_path = utils.is_wsl_windows_fs_path(absolute_path)
    end

    if parent.is_wsl_windows_fs_path then
      return utils.is_wsl_windows_fs_exe(ext)
    end
  end
  return vim.loop.fs_access(absolute_path, "X")
end

function M.file(parent, absolute_path, name)
  local ext = string.match(name, ".?[^.]+%.(.*)") or ""

  return {
    type = "file",
    absolute_path = absolute_path,
    executable = M.is_executable(parent, absolute_path, ext),
    extension = ext,
    fs_stat = vim.loop.fs_stat(absolute_path),
    name = name,
    parent = parent,
  }
end

-- TODO-INFO: sometimes fs_realpath returns nil
-- I expect this be a bug in glibc, because it fails to retrieve the path for some
-- links (for instance libr2.so in /usr/lib) and thus even with a C program realpath fails
-- when it has no real reason to. Maybe there is a reason, but errno is definitely wrong.
-- So we need to check for link_to ~= nil when adding new links to the main tree
function M.link(parent, absolute_path, name)
  --- I dont know if this is needed, because in my understanding, there isn't hard links in windows, but just to be sure i changed it.
  local link_to = vim.loop.fs_realpath(absolute_path)
  local open, nodes, has_children

  local is_dir_link = (link_to ~= nil) and vim.loop.fs_stat(link_to).type == "directory"

  if is_dir_link then
    local handle = vim.loop.fs_scandir(link_to)
    has_children = handle and vim.loop.fs_scandir_next(handle) ~= nil
    open = false
    nodes = {}
  end

  local node = {
    type = "link",
    absolute_path = absolute_path,
    fs_stat = vim.loop.fs_stat(absolute_path),
    group_next = nil, -- If node is grouped, this points to the next child dir/link node
    has_children = has_children,
    link_to = link_to,
    name = name,
    nodes = nodes,
    open = open,
    parent = parent,
  }

  if is_dir_link then
    node.watcher = watch.create_watcher(node)
  end

  return node
end

return M
