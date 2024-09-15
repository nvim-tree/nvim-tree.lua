local M = {}

M.padding = require "nvim-tree.renderer.components.padding"
M.full_name = require "nvim-tree.renderer.components.full-name"
M.icons = require "nvim-tree.renderer.components.icons"

function M.setup(opts)
  M.padding.setup(opts)
  M.full_name.setup(opts)
  M.icons.setup(opts)
end

return M
