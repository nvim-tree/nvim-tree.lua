local M = {}

M.find_file = require "nvim-tree.actions.tree.find-file"
M.modifiers = require "nvim-tree.actions.tree.modifiers"
M.open = require "nvim-tree.actions.tree.open"
M.toggle = require "nvim-tree.actions.tree.toggle"

function M.setup(opts)
  M.find_file.setup(opts)
  M.modifiers.setup(opts)
  M.open.setup(opts)
  M.toggle.setup(opts)
end

return M
