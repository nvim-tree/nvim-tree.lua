local M = {}

M.collapse_all = require("nvim-tree.actions.tree.modifiers.collapse-all")
M.expand_all = require("nvim-tree.actions.tree.modifiers.expand-all")

function M.setup(opts)
  M.expand_all.setup(opts)
end

return M
