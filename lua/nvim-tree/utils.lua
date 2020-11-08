local M = {}

local path_sep = vim.fn.has('win32') == 1 and [[\]] or '/'

function M.path_join(root, path)
  if M.ends_with_sep(root) then
    return root..path
  else
    return root..path_sep..path
  end
end

function M.ends_with_sep(path)
  return vim.endswith(path, path_sep)
end

function M.has_sep(path)
  return vim.fn.stridx(path, path_sep) ~= -1
end

function M.split_path(path)
  return vim.split(path, path_sep, true)
end

function M.concat_path(paths)
  return table.concat(paths, path_sep)
end

function M.remove_last_part(path)
  return path:gsub(path_sep..'[^'..path_sep..']*$', '')
end

function M.warn(msg)
  vim.api.nvim_command(
    string.format([[echohl WarningMsg | echo "%s" | echohl None]], msg)
  )
end

return M
