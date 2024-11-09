local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorCut: Decorator
local DecoratorCut = Decorator:extend()

---@class DecoratorCut
---@overload fun(explorer: DecoratorArgs): DecoratorCut

---@protected
---@param args DecoratorArgs
function DecoratorCut:new(args)
  Decorator.new(self, {
    explorer       = args.explorer,
    enabled        = true,
    hl_pos         = args.explorer.opts.renderer.highlight_clipboard or "none",
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
