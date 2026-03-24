local M = {}

M.finders = require("nvim-tree.actions.finders")
M.moves = require("nvim-tree.actions.moves")
M.tree = require("nvim-tree.actions.tree")

function M.setup(opts)
  M.tree.setup(opts)
end

return M
