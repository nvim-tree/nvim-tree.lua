local BuiltinDecorator = require("nvim-tree.renderer.decorator.builtin")

---@class (exact) CutDecorator: BuiltinDecorator
local CutDecorator = BuiltinDecorator:extend()

---@class CutDecorator
---@overload fun(args: BuiltinDecoratorArgs): CutDecorator

---@protected
---@param args BuiltinDecoratorArgs
function CutDecorator:new(args)
  CutDecorator.super.new(self, args)

  self.enabled         = true
  self.highlight_range = self.explorer.opts.renderer.highlight_clipboard or "none"
  self.icon_placement  = "none"
end

---Cut highlight: renderer.highlight_clipboard and node is cut
---@param node Node
---@return string? highlight_group
function CutDecorator:highlight_group(node)
  if self.highlight_range ~= "none" and self.explorer.clipboard:is_cut(node) then
    return "NvimTreeCutHL"
  end
end

return CutDecorator
