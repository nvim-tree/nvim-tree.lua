local log = require "nvim-tree.log"

local M = {}

local HL = {}

function M.get_highlight(node)
  return M.config.renderer.highlight_diagnostics and HL[node.diag_status]
end

function M.setup(opts)
  M.config = {}
  M.config.diagnostics = opts.diagnostics
  M.config.renderer = opts.renderer

  HL[vim.diagnostic.severity.ERROR] = "NvimTreeLspDiagnosticsErrorText"
  HL[vim.diagnostic.severity.WARN] = "NvimTreeLspDiagnosticsWarningText"
  HL[vim.diagnostic.severity.INFO] = "NvimTreeLspDiagnosticsInfoText"
  HL[vim.diagnostic.severity.HINT] = "NvimTreeLspDiagnosticsHintText"
end

return M
