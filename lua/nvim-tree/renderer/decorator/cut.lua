local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorCut: Decorator
---@field private explorer Explorer
local DecoratorCut = Decorator:extend()

---@class DecoratorCut
---@overload fun(args: DecoratorArgs): DecoratorCut

---@protected
---@param args DecoratorArgs
function DecoratorCut:new(args)
  self.explorer = args.explorer

  ---@type AbstractDecoratorArgs
  local a = {
    enabled         = true,
    highlight_range = self.explorer.opts.renderer.highlight_clipboard or "none",
    icon_placement  = "none",
  }

  DecoratorCut.super.new(self, a)
end

---Cut highlight: renderer.highlight_clipboard and node is cut
---@param node Node
---@return string? highlight_group
function DecoratorCut:highlight_group(node)
  if self.highlight_range ~= "none" and self.explorer.clipboard:is_cut(node) then
    return "NvimTreeCutHL"
  end
end

return DecoratorCut
