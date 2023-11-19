local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

local Decorator = require "nvim-tree.renderer.decorator"

-- highlight groups by severity
local HG_ICON = {
  [vim.diagnostic.severity.ERROR] = "NvimTreeDiagnosticErrorIcon",
  [vim.diagnostic.severity.WARN] = "NvimTreeDiagnosticWarningIcon",
  [vim.diagnostic.severity.INFO] = "NvimTreeDiagnosticInfoIcon",
  [vim.diagnostic.severity.HINT] = "NvimTreeDiagnosticHintIcon",
}
local HG_FILE = {
  [vim.diagnostic.severity.ERROR] = "NvimTreeDiagnosticErrorFileHL",
  [vim.diagnostic.severity.WARN] = "NvimTreeDiagnosticWarningFileHL",
  [vim.diagnostic.severity.INFO] = "NvimTreeDiagnosticInfoFileHL",
  [vim.diagnostic.severity.HINT] = "NvimTreeDiagnosticHintFileHL",
}
local HG_FOLDER = {
  [vim.diagnostic.severity.ERROR] = "NvimTreeDiagnosticErrorFolderHL",
  [vim.diagnostic.severity.WARN] = "NvimTreeDiagnosticWarningFolderHL",
  [vim.diagnostic.severity.INFO] = "NvimTreeDiagnosticInfoFolderHL",
  [vim.diagnostic.severity.HINT] = "NvimTreeDiagnosticHintFolderHL",
}
-- opts.diagnostics.icons.
local ICON_KEYS = {
  ["error"] = vim.diagnostic.severity.ERROR,
  ["warning"] = vim.diagnostic.severity.WARN,
  ["info"] = vim.diagnostic.severity.INFO,
  ["hint"] = vim.diagnostic.severity.HINT,
}

--- @class DecoratorDiagnostics: Decorator
--- @field icons HighlightedString[]
local DecoratorDiagnostics = Decorator:new()

--- @param opts table
--- @return DecoratorDiagnostics
function DecoratorDiagnostics:new(opts)
  local o = Decorator.new(self, {
    enabled = opts.diagnostics.enable,
    hl_pos = HL_POSITION[opts.renderer.highlight_diagnostics] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT[opts.renderer.icons.diagnostics_placement] or ICON_PLACEMENT.none,
  })
  ---@cast o DecoratorDiagnostics

  if not o.enabled then
    return o
  end

  if opts.renderer.icons.show.diagnostics then
    o.icons = {}
    for name, sev in pairs(ICON_KEYS) do
      o.icons[sev] = {
        str = opts.diagnostics.icons[name],
        hl = { HG_ICON[sev] },
      }
      o:define_sign(o.icons[sev])
    end
  end

  return o
end

--- Diagnostic icon: diagnostics.enable, renderer.icons.show.diagnostics and node has status
function DecoratorDiagnostics:calculate_icons(node)
  if node and self.enabled and self.icons then
    if node.diag_status then
      return { self.icons[node.diag_status] }
    end
  end
end

--- Diagnostic highlight: diagnostics.enable, renderer.highlight_diagnostics and node has status
function DecoratorDiagnostics:calculate_highlight(node)
  if not node or not self.enabled or self.hl_pos == HL_POSITION.none then
    return nil
  end

  local group
  if node.nodes then
    group = HG_FOLDER[node.diag_status]
  else
    group = HG_FILE[node.diag_status]
  end

  if group then
    return group
  else
    return nil
  end
end

return DecoratorDiagnostics
