local M = {}
local uv = vim.loop -- or require("luv") ? i dont understand
local api = vim.api

function M.path_to_matching_str(path)
  return path:gsub('(%-)', '(%%-)'):gsub('(%.)', '(%%.)'):gsub('(%_)', '(%%_)')
end

function M.echo_warning(msg)
  api.nvim_command('echohl WarningMsg')
  api.nvim_command("echom '[NvimTree] "..msg:gsub("'", "''").."'")
  api.nvim_command('echohl None')
end

function M.read_file(path)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then return '' end
  local stat = uv.fs_fstat(fd)
  if not stat then return '' end
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data or ''
end

local path_separator = package.config:sub(1,1)
function M.path_join(paths)
  return table.concat(paths, path_separator)
end

function M.path_split(path)
  return path:gmatch('[^'..path_separator..']+'..path_separator..'?')
end

---Get the basename of the given path.
---@param path string
---@return string
function M.path_basename(path)
  path = M.path_remove_trailing(path)
  local i = path:match("^.*()" .. path_separator)
  if not i then return path end
  return path:sub(i + 1, #path)
end

---Get a path relative to another path.
---@param path string
---@param relative_to string
---@return string
function M.path_relative(path, relative_to)
  local p, _ = path:gsub("^" .. M.path_to_matching_str(M.path_add_trailing(relative_to)), "")
  return p
end

function M.path_add_trailing(path)
  if path:sub(-1) == path_separator then
    return path
  end

  return path..path_separator
end

function M.path_remove_trailing(path)
  local p, _ = path:gsub(path_separator..'$', '')
  return p
end

M.path_separator = path_separator

-- get the node from the tree that matches the predicate
-- @param nodes list of node
-- @param fn    function(node): boolean
function M.find_node(nodes, fn)
  local i = 1
  for _, node in ipairs(nodes) do
    if fn(node) then return node, i end
    if node.open and #node.entries > 0 then
      local n, idx = M.find_node(node.entries, fn)
      i = i + idx
      if n then return n, i end
    else
      i = i + 1
    end
  end
  return nil, i
end

return M
