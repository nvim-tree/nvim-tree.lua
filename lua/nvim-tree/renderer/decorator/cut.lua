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

  DecoratorCut.super.new(self, {
    enabled        = true,
    hl_pos         = self.explorer.opts.renderer.highlight_clipboard or "none",
    icon_placement = "none",
  })
end

---Cut highlight: renderer.highlight_clipboard and node is cut
---@param node Node
---@return string|nil group
function DecoratorCut:calculate_highlight(node)
  if self.range ~= "none" and self.explorer.clipboard:is_cut(node) then
    return "NvimTreeCutHL"
  end
end

return DecoratorCut
