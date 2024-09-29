local M = {}

M.finders = require("nvim-tree.actions.finders")
M.fs = require("nvim-tree.actions.fs")
M.moves = require("nvim-tree.actions.moves")
M.node = require("nvim-tree.actions.node")
M.root = require("nvim-tree.actions.root")
M.tree = require("nvim-tree.actions.tree")

function M.setup(opts)
  M.fs.setup(opts)
  M.node.setup(opts)
  M.root.setup(opts)
  M.tree.setup(opts)
end

return M
