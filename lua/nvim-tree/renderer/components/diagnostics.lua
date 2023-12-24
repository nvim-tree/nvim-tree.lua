local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local diagnostics = require "nvim-tree.diagnostics"

local M = {
  HS_FILE = {},
  HS_FOLDER = {},
  ICON = {},
  hl_pos = HL_POSITION.none,
}

---Diagnostics text highlight group when highlight_diagnostics.
---@param node table
---@return HL_POSITION position none when no status
---@return string|nil group only when status
function M.get_highlight(node)
  if not node or M.hl_pos == HL_POSITION.none then
    return HL_POSITION.none, nil
  end

  local group
  local diag_status = diagnostics.get_diag_status(node)
  if node.nodes then
    group = M.HS_FOLDER[diag_status and diag_status.value]
  else
    group = M.HS_FILE[diag_status and diag_status.value]
  end

  if group then
    return M.hl_pos, group
  else
    return HL_POSITION.none, nil
  end
end

---diagnostics icon if there is a status
---@param node table
---@return HighlightedString|nil modified icon
function M.get_icon(node)
  if node and M.config.diagnostics.enable and M.config.renderer.icons.show.diagnostics then
    local diag_status = diagnostics.get_diag_status(node)
    return M.ICON[diag_status and diag_status.value]
  end
end

function M.setup(opts)
  M.config = {
    diagnostics = opts.diagnostics,
    renderer = opts.renderer,
  }

  if opts.diagnostics.enable and opts.renderer.highlight_diagnostics then
    -- TODO add a HL_POSITION
    -- M.hl_pos = HL_POSITION[opts.renderer.highlight_diagnostics]
    M.hl_pos = HL_POSITION.name
  end

  M.HS_FILE[vim.diagnostic.severity.ERROR] = "NvimTreeLspDiagnosticsErrorText"
  M.HS_FILE[vim.diagnostic.severity.WARN] = "NvimTreeLspDiagnosticsWarningText"
  M.HS_FILE[vim.diagnostic.severity.INFO] = "NvimTreeLspDiagnosticsInfoText"
  M.HS_FILE[vim.diagnostic.severity.HINT] = "NvimTreeLspDiagnosticsHintText"

  M.HS_FOLDER[vim.diagnostic.severity.ERROR] = "NvimTreeLspDiagnosticsErrorFolderText"
  M.HS_FOLDER[vim.diagnostic.severity.WARN] = "NvimTreeLspDiagnosticsWarningFolderText"
  M.HS_FOLDER[vim.diagnostic.severity.INFO] = "NvimTreeLspDiagnosticsInfoFolderText"
  M.HS_FOLDER[vim.diagnostic.severity.HINT] = "NvimTreeLspDiagnosticsHintFolderText"

  M.ICON[vim.diagnostic.severity.ERROR] = {
    str = M.config.diagnostics.icons.error,
    hl = { "NvimTreeLspDiagnosticsError" },
  }

  M.ICON[vim.diagnostic.severity.WARN] = {
    str = M.config.diagnostics.icons.warning,
    hl = { "NvimTreeLspDiagnosticsWarning" },
  }
  M.ICON[vim.diagnostic.severity.INFO] = {
    str = M.config.diagnostics.icons.info,
    hl = { "NvimTreeLspDiagnosticsInformation" },
  }
  M.ICON[vim.diagnostic.severity.HINT] = {
    str = M.config.diagnostics.icons.hint,
    hl = { "NvimTreeLspDiagnosticsHint" },
  }

  for _, i in ipairs(M.ICON) do
    vim.fn.sign_define(i.hl[1], { text = i.str, texthl = i.hl[1] })
  end
end

return M
