local a = vim.api
local M = {}

function M.rename(node_name)
  local line = a.nvim_get_current_line()
  vim.cmd(":q!")
  if #line == 0 or line == node_name then return end

  local bufs = a.nvim_list_bufs()

  -- rename node
  -- for each buf that has .*/nodename/?.*, replace nodename with new name
  -- send refresh node
end

return M
