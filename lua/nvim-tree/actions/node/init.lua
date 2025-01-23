local M = {}

M.file_popup = require("nvim-tree.actions.node.file-popup")
M.open_file = require("nvim-tree.actions.node.open-file")
M.run_command = require("nvim-tree.actions.node.run-command")
M.system_open = require("nvim-tree.actions.node.system-open")
M.buffer = require("nvim-tree.actions.node.buffer")

function M.setup(opts)
  require("nvim-tree.actions.node.system-open").setup(opts)
  require("nvim-tree.actions.node.file-popup").setup(opts)
  require("nvim-tree.actions.node.open-file").setup(opts)
end

return M
