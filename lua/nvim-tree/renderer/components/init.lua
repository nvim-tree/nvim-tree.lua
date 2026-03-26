local M = {}

M.devicons = require("nvim-tree.renderer.components.devicons")
M.padding = require("nvim-tree.renderer.components.padding")

function M.setup(opts)
  M.devicons.setup(opts)
  M.padding.setup(opts)
end

return M
