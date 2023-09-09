local M = {}

local HS_FILE = {}
local HS_FOLDER = {}
local ICON = {}

---diagnostics text highlight group if there is a status
---@param node table
---@return string|nil highlight
function M.get_highlight(node)
  if node and M.config.diagnostics.enable and M.config.renderer.highlight_diagnostics then
    if node.nodes then
      return HS_FOLDER[node.diag_status]
    else
      return HS_FILE[node.diag_status]
    end
  end
end

---diagnostics icon if there is a status
---@param node table
---@return HighlightedString|nil modified icon
function M.get_icon(node)
  if node and M.config.diagnostics.enable and M.config.renderer.icons.show.diagnostics then
    return ICON[node.diag_status]
  end
end

function M.setup(opts)
  M.config = {
    diagnostics = opts.diagnostics,
    renderer = opts.renderer,
  }

  HS_FILE[vim.diagnostic.severity.ERROR] = "NvimTreeLspDiagnosticsErrorText"
  HS_FILE[vim.diagnostic.severity.WARN] = "NvimTreeLspDiagnosticsWarningText"
  HS_FILE[vim.diagnostic.severity.INFO] = "NvimTreeLspDiagnosticsInfoText"
  HS_FILE[vim.diagnostic.severity.HINT] = "NvimTreeLspDiagnosticsHintText"

  HS_FOLDER[vim.diagnostic.severity.ERROR] = "NvimTreeLspDiagnosticsErrorFolderText"
  HS_FOLDER[vim.diagnostic.severity.WARN] = "NvimTreeLspDiagnosticsWarningFolderText"
  HS_FOLDER[vim.diagnostic.severity.INFO] = "NvimTreeLspDiagnosticsInfoFolderText"
  HS_FOLDER[vim.diagnostic.severity.HINT] = "NvimTreeLspDiagnosticsHintFolderText"

  ICON[vim.diagnostic.severity.ERROR] = {
    str = M.config.diagnostics.icons.error,
    hl = "NvimTreeLspDiagnosticsError",
  }

  ICON[vim.diagnostic.severity.WARN] = {
    str = M.config.diagnostics.icons.warning,
    hl = "NvimTreeLspDiagnosticsWarning",
  }
  ICON[vim.diagnostic.severity.INFO] = {
    str = M.config.diagnostics.icons.info,
    hl = "NvimTreeLspDiagnosticsInfo",
  }
  ICON[vim.diagnostic.severity.HINT] = {
    str = M.config.diagnostics.icons.hint,
    hl = "NvimTreeLspDiagnosticsHint",
  }

  for _, i in ipairs(ICON) do
    vim.fn.sign_define(i.hl, { text = i.str, texthl = i.hl })
  end
end

return M
