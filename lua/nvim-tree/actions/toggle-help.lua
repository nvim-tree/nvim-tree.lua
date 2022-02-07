local M = {}

function M.fn()
  require"nvim-tree.view".toggle_help()
  return require"nvim-tree.lib".redraw()
end

return M
