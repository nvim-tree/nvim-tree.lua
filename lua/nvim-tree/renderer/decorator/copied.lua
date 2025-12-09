local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) CopiedDecorator: Decorator
---@field private explorer Explorer
local CopiedDecorator = Decorator:extend()

---@class CopiedDecorator
---@overload fun(args: DecoratorArgs): CopiedDecorator

---@protected
---@param args DecoratorArgs
function CopiedDecorator:new(args)
  self.explorer        = args.explorer

  self.enabled         = true
  self.highlight_range = self.explorer.opts.renderer.highlight_clipboard or "none"
  self.icon_placement  = "none"
end

---Copied highlight: renderer.highlight_clipboard and node is copied
---@param node Node
---@return string? highlight_group
function CopiedDecorator:highlight_group(node)
  if self.highlight_range ~= "none" and self.explorer.clipboard:is_copied(node) then
    return "NvimTreeCopiedHL"
  end
end

return CopiedDecorator
