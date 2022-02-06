local M = {}

M.explore = require"nvim-tree.explorer.explore".explore
M.reload = require"nvim-tree.explorer.reload".reload

function M.setup(opts)
  require"nvim-tree.explorer.utils".setup(opts)
end

return M
