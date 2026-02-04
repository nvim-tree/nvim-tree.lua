local BuiltinDecorator = require("nvim-tree.renderer.decorator.builtin")

---@class (exact) CopiedDecorator: BuiltinDecorator
---@field private explorer Explorer
local CopiedDecorator = BuiltinDecorator:extend()

---@class CopiedDecorator
---@overload fun(args: BuiltinDecoratorArgs): CopiedDecorator

---@protected
---@param args BuiltinDecoratorArgs
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
