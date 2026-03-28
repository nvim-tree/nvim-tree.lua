local M = {}

M.padding = require("nvim-tree.renderer.components.padding")

function M.setup(opts)
  M.padding.setup(opts)
end

return M
