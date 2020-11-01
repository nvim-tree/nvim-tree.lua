local M = {}

local path_sep = vim.fn.has('win32') == 1 and [[\]] or '/'

function M.path_join(root, path)
  return root..path_sep..path
end

function M.warn(msg)
  vim.api.nvim_command(
    string.format([[echohl WarningMsg | echo "%s" | echohl None]], msg)
  )
end

return M
