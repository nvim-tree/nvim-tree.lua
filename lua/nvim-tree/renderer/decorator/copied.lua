local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorCopied: Decorator
local DecoratorCopied = Decorator:extend()

---@class DecoratorCopied
---@overload fun(explorer: DecoratorArgs): DecoratorCopied

---@protected
---@param args DecoratorArgs
function DecoratorCopied:new(args)
  Decorator.new(self, {
    explorer       = args.explorer,
    enabled        = true,
    hl_pos         = args.explorer.opts.renderer.highlight_clipboard or "none",
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
