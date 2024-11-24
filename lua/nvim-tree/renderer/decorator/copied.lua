local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorCopied: Decorator
---@field private explorer Explorer
local DecoratorCopied = Decorator:extend()
DecoratorCopied.name = "Copied"

---@class DecoratorCopied
---@overload fun(args: DecoratorArgs): DecoratorCopied

---@protected
---@param args DecoratorArgs
function DecoratorCopied:new(args)
  self.explorer = args.explorer

  ---@type AbstractDecoratorArgs
  local a = {
    enabled         = true,
    highlight_range = self.explorer.opts.renderer.highlight_clipboard or "none",
    icon_placement  = "none",
  }

  DecoratorCopied.super.new(self, a)
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
