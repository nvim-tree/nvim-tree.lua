local M = {}

M.devicons = require("nvim-tree.renderer.components.devicons")

function M.setup(opts)
  M.devicons.setup(opts)
end

return M
