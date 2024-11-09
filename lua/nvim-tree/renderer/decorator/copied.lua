local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorCopied: Decorator
---@field private explorer Explorer
local DecoratorCopied = Decorator:extend()

---@class DecoratorCopied
---@overload fun(explorer: Explorer): DecoratorCopied

---@protected
---@param explorer Explorer
function DecoratorCopied:new(explorer)
  self.explorer = explorer

  DecoratorCopied.super.new(self, {
    enabled        = true,
    hl_pos         = self.explorer.opts.renderer.highlight_clipboard or "none",
    icon_placement = "none",
  })
end

---Copied highlight: renderer.highlight_clipboard and node is copied
---@param node Node
---@return string|nil group
function DecoratorCopied:calculate_highlight(node)
  if self.range ~= "none" and self.explorer.clipboard:is_copied(node) then
    return "NvimTreeCopiedHL"
  end
end

return DecoratorCopied
