local M = {}

M.diagnostics = require("nvim-tree.renderer.components.diagnostics")
M.full_name = require("nvim-tree.renderer.components.full-name")
M.devicons = require("nvim-tree.renderer.components.devicons")
M.padding = require("nvim-tree.renderer.components.padding")

function M.setup(opts)
  M.diagnostics.setup(opts)
  M.full_name.setup(opts)
  M.devicons.setup(opts)
  M.padding.setup(opts)
end

return M
