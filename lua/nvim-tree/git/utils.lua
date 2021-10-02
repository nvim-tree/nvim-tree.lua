local M = {}

function M.get_toplevel(cwd)
  local cmd = "git -C " .. vim.fn.shellescape(cwd) .. " rev-parse --show-toplevel"
  local toplevel = vim.fn.system(cmd)

  if not toplevel or #toplevel == 0 or toplevel:match('fatal') then
    return nil
  end

  -- git always returns path with forward slashes
  if vim.fn.has('win32') == 1 then
    toplevel = toplevel:gsub("/", "\\")
  end

  -- remove newline
  return toplevel:sub(0, -2)
end

function M.show_untracked(cwd)
  local cmd = "git -C "..cwd.." config --type=bool status.showUntrackedFiles"
  local has_untracked = vim.fn.system(cmd)
  return vim.trim(has_untracked) ~= 'false'
end

return M
