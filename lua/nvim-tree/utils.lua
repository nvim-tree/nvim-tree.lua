local M = {}
local api = vim.api

function M.path_to_matching_str(path)
  return path:gsub('(%-)', '(%%-)'):gsub('(%.)', '(%%.)'):gsub('(%_)', '(%%_)')
end

function M.echo_warning(msg)
  api.nvim_command('echohl WarningMsg')
  api.nvim_command("echom '[NvimTree] "..msg:gsub("'", "''").."'")
  api.nvim_command('echohl None')
end

local path_separator = package.config:sub(1,1)
function M.path_join(paths)
  return table.concat(paths, path_separator)
end

function M.path_split(path)
  return path:gmatch('[^'..path_separator..']+'..path_separator..'?')
end

function M.path_add_trailing(path)
  if path:sub(-1) == path_separator then
    return path
  end

  return path..path_separator
end

function M.path_remove_trailing(path)
  return path:gsub(path_separator..'$', '')
end

M.path_separator = path_separator
return M
