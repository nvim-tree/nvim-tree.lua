local diagnostics = require("nvim-tree.diagnostics")

local Decorator = require("nvim-tree.renderer.decorator")
local DirectoryNode = require("nvim-tree.node.directory")

-- highlight groups by severity
local HG_ICON = {
  [vim.diagnostic.severity.ERROR] = "NvimTreeDiagnosticErrorIcon",
  [vim.diagnostic.severity.WARN] = "NvimTreeDiagnosticWarnIcon",
  [vim.diagnostic.severity.INFO] = "NvimTreeDiagnosticInfoIcon",
  [vim.diagnostic.severity.HINT] = "NvimTreeDiagnosticHintIcon",
}
local HG_FILE = {
  [vim.diagnostic.severity.ERROR] = "NvimTreeDiagnosticErrorFileHL",
  [vim.diagnostic.severity.WARN] = "NvimTreeDiagnosticWarnFileHL",
  [vim.diagnostic.severity.INFO] = "NvimTreeDiagnosticInfoFileHL",
  [vim.diagnostic.severity.HINT] = "NvimTreeDiagnosticHintFileHL",
}
local HG_FOLDER = {
  [vim.diagnostic.severity.ERROR] = "NvimTreeDiagnosticErrorFolderHL",
  [vim.diagnostic.severity.WARN] = "NvimTreeDiagnosticWarnFolderHL",
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

---@class (exact) DecoratorDiagnostics: Decorator
---@field icons HighlightedString[]?
local DecoratorDiagnostics = Decorator:extend()

---@class DecoratorDiagnostics
---@overload fun(explorer: DecoratorArgs): DecoratorDiagnostics

---@protected
---@param args DecoratorArgs
function DecoratorDiagnostics:new(args)
  Decorator.new(self, {
    explorer       = args.explorer,
    enabled        = true,
    hl_pos         = args.explorer.opts.renderer.highlight_diagnostics or "none",
    icon_placement = args.explorer.opts.renderer.icons.diagnostics_placement or "none",
  })

  if not self.enabled then
    return
  end

  if self.explorer.opts.renderer.icons.show.diagnostics then
    self.icons = {}
    for name, sev in pairs(ICON_KEYS) do
      self.icons[sev] = {
        str = self.explorer.opts.diagnostics.icons[name],
        hl = { HG_ICON[sev] },
      }
      self:define_sign(self.icons[sev])
    end
  end
end

---Diagnostic icon: diagnostics.enable, renderer.icons.show.diagnostics and node has status
---@param node Node
---@return HighlightedString[]|nil icons
function DecoratorDiagnostics:calculate_icons(node)
  if node and self.enabled and self.icons then
    local diag_status = diagnostics.get_diag_status(node)
    local diag_value = diag_status and diag_status.value

    if diag_value then
      return { self.icons[diag_value] }
    end
  end
end

---Diagnostic highlight: diagnostics.enable, renderer.highlight_diagnostics and node has status
---@param node Node
---@return string|nil group
function DecoratorDiagnostics:calculate_highlight(node)
  if not node or not self.enabled or self.range == "none" then
    return nil
  end

  local diag_status = diagnostics.get_diag_status(node)
  local diag_value = diag_status and diag_status.value

  if not diag_value then
    return nil
  end

  local group
  if node:is(DirectoryNode) then
    group = HG_FOLDER[diag_value]
  else
    group = HG_FILE[diag_value]
  end

  if group then
    return group
  else
    return nil
  end
end

return DecoratorDiagnostics
