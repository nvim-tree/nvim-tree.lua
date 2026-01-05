local M = {}

M.collapse = require("nvim-tree.actions.tree.modifiers.collapse")
M.expand = require("nvim-tree.actions.tree.modifiers.expand")

function M.setup(opts)
  M.expand.setup(opts)
end

return M
