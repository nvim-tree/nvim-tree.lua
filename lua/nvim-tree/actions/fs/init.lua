local M = {}

M.create_file = require("nvim-tree.actions.fs.create-file")
M.remove_file = require("nvim-tree.actions.fs.remove-file")
M.rename_file = require("nvim-tree.actions.fs.rename-file")
M.trash = require("nvim-tree.actions.fs.trash")

return M
