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

function M.path_basename(path)
  path = M.path_remove_trailing(path)
  local i = path:match("^.*()" .. path_separator)
  if not i then return path end
  return path:sub(i + 1, #path)
end

function M.path_relative(path, relative_to)
  return path:gsub("^" .. M.path_to_matching_str(M.path_add_trailing(relative_to)), "")
end

---Add a trailing separator to a given path. If no separator is given, the
---platform default is used.
---@param path string
---@param separator string|nil
---@return string
function M.path_add_trailing(path, separator)
  if not separator then separator = path_separator end
  if path:sub(-1) == separator then
    return path
  end

  return path..separator
end

---Remove a trailing separator from a given path. If no separator is given,
---the platform default is used.
---@param path string
---@param separator string|nil
---@return string
function M.path_remove_trailing(path, separator)
  if not separator then separator = path_separator end
  local p, _ = path:gsub(separator..'$', '')
  return p
end

M.path_separator = path_separator
return M
