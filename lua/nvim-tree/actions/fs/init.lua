local M = {}

M.create_file = require("nvim-tree.actions.fs.create-file")
M.remove_file = require("nvim-tree.actions.fs.remove-file")
M.rename_file = require("nvim-tree.actions.fs.rename-file")
M.trash = require("nvim-tree.actions.fs.trash")

function M.setup(opts)
  M.remove_file.setup(opts)
  M.rename_file.setup(opts)
  M.trash.setup(opts)
end

return M
