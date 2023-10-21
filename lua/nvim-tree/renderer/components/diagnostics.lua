local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local diagnostics = require "nvim-tree.diagnostics"

local M = {
  -- highlight strings for the icons
  HS_ICON = {},

  -- highlight groups for HL
  HG_FILE = {},
  HG_FOLDER = {},

  -- position for HL
  HL_POS = HL_POSITION.none,
}

---Diagnostics highlight group and position when highlight_diagnostics.
---@param node table
---@return HL_POSITION position none when no status
---@return string|nil group only when status
function M.get_highlight(node)
  if not node or M.HL_POS == HL_POSITION.none then
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
    return M.HL_POS, group
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
    M.HL_POS = HL_POSITION[opts.renderer.highlight_diagnostics]
  end

  M.HG_FILE[vim.diagnostic.severity.ERROR] = "NvimTreeDiagnosticErrorFileHL"
  M.HG_FILE[vim.diagnostic.severity.WARN] = "NvimTreeDiagnosticWarningFileHL"
  M.HG_FILE[vim.diagnostic.severity.INFO] = "NvimTreeDiagnosticInfoFileHL"
  M.HG_FILE[vim.diagnostic.severity.HINT] = "NvimTreeDiagnosticHintFileHL"

  M.HG_FOLDER[vim.diagnostic.severity.ERROR] = "NvimTreeDiagnosticErrorFolderHL"
  M.HG_FOLDER[vim.diagnostic.severity.WARN] = "NvimTreeDiagnosticWarningFolderHL"
  M.HG_FOLDER[vim.diagnostic.severity.INFO] = "NvimTreeDiagnosticInfoFolderHL"
  M.HG_FOLDER[vim.diagnostic.severity.HINT] = "NvimTreeDiagnosticHintFolderHL"

  M.HS_ICON[vim.diagnostic.severity.ERROR] = {
    str = M.config.diagnostics.icons.error,
    hl = { "NvimTreeDiagnosticErrorIcon" },
  }

  M.HS_ICON[vim.diagnostic.severity.WARN] = {
    str = M.config.diagnostics.icons.warning,
    hl = { "NvimTreeDiagnosticWarningIcon" },
  }
  M.HS_ICON[vim.diagnostic.severity.INFO] = {
    str = M.config.diagnostics.icons.info,
    hl = { "NvimTreeDiagnosticInfoIcon" },
  }
  M.HS_ICON[vim.diagnostic.severity.HINT] = {
    str = M.config.diagnostics.icons.hint,
    hl = { "NvimTreeDiagnosticHintIcon" },
  }

  for _, i in ipairs(M.HS_ICON) do
    vim.fn.sign_define(i.hl[1], { text = i.str, texthl = i.hl[1] })
  end
end

return M
