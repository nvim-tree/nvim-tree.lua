local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorCopied: Decorator
local DecoratorCopied = Decorator:extend()

---@class DecoratorCopied
---@overload fun(explorer: DecoratorArgs): DecoratorCopied

---@private
---@param args DecoratorArgs
function DecoratorCopied:new(args)
  Decorator.new(self, {
    explorer       = args.explorer,
    enabled        = true,
    hl_pos         = HL_POSITION[args.explorer.opts.renderer.highlight_clipboard] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT.none,
  })
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
