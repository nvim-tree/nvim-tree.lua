local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorCopied: Decorator
---@field icon HighlightedString?
local DecoratorCopied = Decorator:new()

---Static factory method
---@param opts table
---@param explorer Explorer
---@return DecoratorCopied
function DecoratorCopied:create(opts, explorer)
  ---@type DecoratorCopied
  local o = {
    explorer = explorer,
    enabled = true,
    hl_pos = HL_POSITION[opts.renderer.highlight_clipboard] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT.none,
  }
  o = self:new(o)

  return o
end

---Copied highlight: renderer.highlight_clipboard and node is copied
---@param node Node
---@return string|nil group
function DecoratorCopied:calculate_highlight(node)
  if self.hl_pos ~= HL_POSITION.none and self.explorer.clipboard:is_copied(node) then
    return "NvimTreeCopiedHL"
  end
end

return DecoratorCopied
