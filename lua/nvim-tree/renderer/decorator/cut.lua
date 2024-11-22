local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorCut: Decorator
---@field private explorer Explorer
local DecoratorCut = Decorator:extend()

---@class DecoratorCut
---@overload fun(explorer: Explorer): DecoratorCut

---@protected
---@param explorer Explorer
function DecoratorCut:new(explorer)
  self.explorer = explorer

  ---@type DecoratorArgs
  local args = {
    enabled         = true,
    highlight_range = self.explorer.opts.renderer.highlight_clipboard or "none",
    icon_placement  = "none",
  }

  DecoratorCut.super.new(self, args)
end

---Cut highlight: renderer.highlight_clipboard and node is cut
---@param node Node
---@return string|nil group
function DecoratorCut:highlight_group(node)
  if self.highlight_range ~= "none" and self.explorer.clipboard:is_cut(node) then
    return "NvimTreeCutHL"
  end
end

return DecoratorCut
