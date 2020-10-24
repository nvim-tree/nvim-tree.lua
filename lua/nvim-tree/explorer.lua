local uv = vim.loop
local a = vim.api

local M = {}

M.Explorer = {
  cwd = uv.cwd(),
  node_tree = {},
  node_pool = {}
}

local path_sep = vim.fn.has('win32') == 1 and '\\' or '/'

local function path_join(root, path)
  return root..path_sep..path
end

local function create_dir(parent, name)
  local absolute_path = path_join(parent, name)
  -- local stat = uv.fs_stat(absolute_path)
  return {
    name = name,
    absolute_path = absolute_path,
    opened = false,
    entries = {},
    -- INFO/TODO: last modified could also involve atime and ctime
    -- last_modified = stat.mtime.sec,
    -- match_name = path_to_matching_str(name),
    -- match_path = path_to_matching_str(absolute_path),
  }
end

local function create_file(parent, name)
  local absolute_path = path_join(parent, name)
  local executable = uv.fs_access(absolute_path, 'X')
  return {
    name = name,
    absolute_path = absolute_path,
    executable = executable,
    extension = vim.fn.fnamemodify(name, ':e') or "",
    -- match_name = path_to_matching_str(name),
    -- match_path = path_to_matching_str(absolute_path),
  }
end

local function create_symlink(parent, name)
  local absolute_path = path_join(parent, name)
  local link_to = uv.fs_realpath(absolute_path)
  return {
    name = name,
    absolute_path = absolute_path,
    link_to = link_to,
    -- match_name = path_to_matching_str(name),
    -- match_path = path_to_matching_str(absolute_path),
  }
end

function M.Explorer:is_file_ignored(file)
  return (M.config.ignore_dotfiles and file:sub(1, 1) == '.')
    or (M.config.show_ignored and M.config.ignore[file] == true)
end

function M.Explorer:explore(dir_extension)
  local cwd = dir_extension and path_join(self.cwd, dir_extension) or self.cwd
  local handle = uv.fs_scandir(cwd)
  if type(handle) == 'string' then
    return nil
  end

  local entries = {
    directories = {},
    symlinks = {},
    files = {}
  }

  while true do
    local entry_name, entry_type = uv.fs_scandir_next(handle)
    if not entry_name then break end

    if not self:is_file_ignored(entry_name) then
      if entry_type == 'file' then
        local dir = create_file(cwd, entry_name)
        if uv.fs_access(dir.absolute_path, 'R') then
          table.insert(entries.files, dir)
        end
      elseif entry_type == 'directory' then
        table.insert(entries.directories, create_dir(cwd, entry_name))
      elseif entry_type == 'link' then
        local symlink = create_symlink(cwd, entry_name)
        if symlink.link_to ~= nil then
          table.insert(entries.symlinks, symlink)
        end
      end
    end
  end

  return vim.tbl_extend("keep", entries.directories, entries.symlinks, entries.files)
end

function M.Explorer:new()
  self.cwd = uv.cwd()
  local entries = self:explore()
  if entries then
    self.node_tree = require'nvim-tree.git'.gitify(entries)
    for _, node in ipairs(entries) do
      self.node_pool[node.absolute_path] = node
    end
  end

  return self
end

function M.configure(opts)
  M.config = {
    ignore = {},
    show_ignored = opts.show_ignored,
    ignore_dotfiles = opts.hide_dotfiles
  }

  for _, ignore_pattern in ipairs(opts.ignore) do
    M.config.ignore[ignore_pattern] = true
  end
end

return M
