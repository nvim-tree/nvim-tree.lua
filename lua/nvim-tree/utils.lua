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

---Join a list of paths.
---@param paths table
---@param separator string|nil If nil, the platform default is used.
---@return string
function M.path_join(paths, separator)
  if not separator then separator = path_separator end
  return table.concat(paths, separator)
end

---Split a given path.
---@param path string
---@param separator string|nil If nil, the platform default is used.
---@return function Iterator
function M.path_split(path, separator)
  if not separator then separator = path_separator end
  return path:gmatch('[^'..separator..']+'..separator..'?')
end

---Get the basename of the given path.
---@param path string
---@param separator string|nil If nil, the platform default is used.
---@return string
function M.path_basename(path, separator)
  if not separator then separator = path_separator end
  path = M.path_remove_trailing(path)
  local i = path:match("^.*()" .. separator)
  if not i then return path end
  return path:sub(i + 1, #path)
end

---Get a path relative to another path.
---@param path string
---@param relative_to string
---@param separator string|nil If nil, the platform default is used.
---@return string
function M.path_relative(path, relative_to, separator)
  if not separator then separator = path_separator end
  local p, _ = path:gsub("^" .. M.path_to_matching_str(M.path_add_trailing(relative_to, separator)), "")
  return p
end

---Add a trailing separator to a given path.
---@param path string
---@param separator string|nil If nil, the platform default is used.
---@return string
function M.path_add_trailing(path, separator)
  if not separator then separator = path_separator end
  if path:sub(-1) == separator then
    return path
  end

  return path..separator
end

---Remove a trailing separator from a given path.
---@param path string
---@param separator string|nil If nil, the platform default is used.
---@return string
function M.path_remove_trailing(path, separator)
  if not separator then separator = path_separator end
  local p, _ = path:gsub(separator..'$', '')
  return p
end

M.path_separator = path_separator
return M
