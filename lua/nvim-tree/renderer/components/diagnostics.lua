local M = {}

local H = {}
local I = {}

---diagnostics text highlight group if there is a status
---@param node table
---@return string|nil highlight
function M.get_highlight(node)
  if M.config.diagnostics.enable and M.config.renderer.highlight_diagnostics then
    return H[node.diag_status]
  end
end

---diagnostics icon if there is a status
---@param node table
---@return HighlightedString|nil modified icon
function M.get_icon(node)
  if M.config.diagnostics.enable then
    return I[node.diag_status]
  end
end

function M.setup(opts)
  M.config = {
    diagnostics = opts.diagnostics,
    renderer = opts.renderer,
  }

  H[vim.diagnostic.severity.ERROR] = "NvimTreeLspDiagnosticsErrorText"
  H[vim.diagnostic.severity.WARN] = "NvimTreeLspDiagnosticsWarningText"
  H[vim.diagnostic.severity.INFO] = "NvimTreeLspDiagnosticsInfoText"
  H[vim.diagnostic.severity.HINT] = "NvimTreeLspDiagnosticsHintText"

  I[vim.diagnostic.severity.ERROR] = {
    str = M.config.diagnostics.icons.error,
    hl = "NvimTreeLspDiagnosticsError",
  }

  I[vim.diagnostic.severity.WARN] = {
    str = M.config.diagnostics.icons.warning,
    hl = "NvimTreeLspDiagnosticsWarning",
  }
  I[vim.diagnostic.severity.INFO] = {
    str = M.config.diagnostics.icons.info,
    hl = "NvimTreeLspDiagnosticsInfo",
  }
  I[vim.diagnostic.severity.HINT] = {
    str = M.config.diagnostics.icons.hint,
    hl = "NvimTreeLspDiagnosticsHint",
  }

  for _, i in ipairs(I) do
    vim.fn.sign_define(i.hl, { text = i.str, texthl = i.hl })
  end
end

return M
