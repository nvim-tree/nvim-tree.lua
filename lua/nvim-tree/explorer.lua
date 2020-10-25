local uv = vim.loop
local a = vim.api

local M = {}

M.Explorer = {
  cwd = uv.cwd(),
  cursor = nil,
  node_tree = {},
  file_pool = {}
}

local path_sep = vim.fn.has('win32') == 1 and [[\]] or '/'

local function path_join(root, path)
  return root..path_sep..path
end

local node_type_funcs = {
  directory = {
    create = function(parent, name)
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
    end,
    check = function(node)
      return uv.fs_access(node.absolute_path, 'R')
    end
  },
  file = {
    create = function(parent, name)
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
  },
  link = {
    create = function(parent, name)
      local absolute_path = path_join(parent, name)
      local link_to = uv.fs_realpath(absolute_path)
      return {
        name = name,
        absolute_path = absolute_path,
        link_to = link_to,
        -- match_name = path_to_matching_str(name),
        -- match_path = path_to_matching_str(absolute_path),
      }
    end,
    check = function(node) return node.link_to ~= nil end
  }
}

function M.Explorer:is_file_ignored(file)
  return (M.config.ignore_dotfiles and file:sub(1, 1) == '.')
    or (M.config.show_ignored and M.config.ignore[file] == true)
end

function M.Explorer:explore(root)
  local cwd = root or self.cwd
  local handle = uv.fs_scandir(cwd)
  if type(handle) == 'string' then
    return nil
  end

  local entries = {
    directory = {},
    symlink = {},
    file = {}
  }

  while true do
    local entry_name, entry_type = uv.fs_scandir_next(handle)
    if not entry_name then break end

    if not self:is_file_ignored(entry_name) then
      local funcs = node_type_funcs[entry_type]
      local entry = funcs.create(cwd, entry_name)

      if not funcs.check or funcs.check(entry) then
        self.file_pool[entry.absolute_path] = 1
        table.insert(entries[entry_type], entry)
      end
    end
  end

  for _, node in pairs(entries.symlink) do
    table.insert(entries.directory, node)
  end
  for _, node in pairs(entries.file) do
    table.insert(entries.directory, node)
  end

  return entries.directory
end

local function find_node(entries, row, idx)
  for _, node in ipairs(entries) do
    if idx == row then return node, idx end

    idx = idx + 1
    if node.opened and #node.entries > 0 then
      local n, i = find_node(node.entries, row, idx)
      if n then return n, i end

      idx = i + 1
    end
  end
end

function M.Explorer:get_node_under_cursor()
  local curpos = a.nvim_win_get_cursor(0)
  local index = 1
  return find_node(self.node_tree, curpos[1], index)
end

-- TODO advanced update/caching mecanism
-- right now it will not remember opened leafs underneath
-- when closing then reopening
function M.Explorer:switch_open_dir(node)
  node.opened = not node.opened

  if not node.opened then return end

  local entries = self:explore(node.absolute_path)
  if entries then
    node.entries = require'nvim-tree.git'.gitify(entries)
  end
end

function M.Explorer:new()
  self.cwd = uv.cwd()
  local entries = self:explore()
  if entries then
    self.node_tree = require'nvim-tree.git'.gitify(entries)
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
