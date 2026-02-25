local M = {}

M.change_dir = require("nvim-tree.actions.tree.change-dir")
M.find_file = require("nvim-tree.actions.tree.find-file")
M.collapse = require("nvim-tree.actions.tree.collapse")
M.open = require("nvim-tree.actions.tree.open")
M.toggle = require("nvim-tree.actions.tree.toggle")
M.resize = require("nvim-tree.actions.tree.resize")

function M.setup(opts)
  M.change_dir.setup(opts)
  M.find_file.setup(opts)
  M.open.setup(opts)
  M.toggle.setup(opts)
  M.resize.setup(opts)
end

return M
