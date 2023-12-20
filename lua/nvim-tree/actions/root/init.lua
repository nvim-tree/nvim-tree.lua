local M = {}

M.change_dir = require "nvim-tree.actions.root.change-dir"
M.dir_up = require "nvim-tree.actions.root.dir-up"

function M.setup(opts)
  M.change_dir.setup(opts)
end

return M
