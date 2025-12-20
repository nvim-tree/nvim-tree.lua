local M = {}

M.change_dir = require("nvim-tree.actions.root.change-dir")

function M.setup(opts)
  M.change_dir.setup(opts)
end

return M
