local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorCopied: Decorator
---@field private explorer Explorer
local DecoratorCopied = Decorator:extend()

---@class DecoratorCopied
---@overload fun(args: DecoratorArgs): DecoratorCopied

---@protected
---@param args DecoratorArgs
function DecoratorCopied:new(args)
  self.explorer   = args.explorer

  self.enabled         = true
  self.highlight_range = self.explorer.opts.renderer.highlight_clipboard or "none"
  self.icon_placement  = "none"
end

---Copied highlight: renderer.highlight_clipboard and node is copied
---@param node Node
---@return string? highlight_group
function DecoratorCopied:highlight_group(node)
  if self.highlight_range ~= "none" and self.explorer.clipboard:is_copied(node) then
    return "NvimTreeCopiedHL"
  end
end

return DecoratorCopied
