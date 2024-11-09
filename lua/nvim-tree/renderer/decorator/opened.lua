local buffers = require("nvim-tree.buffers")

local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorOpened: Decorator
---@field icon HighlightedString|nil
local DecoratorOpened = Decorator:extend()

---@class DecoratorOpened
---@overload fun(explorer: DecoratorArgs): DecoratorOpened

---@protected
---@param args DecoratorArgs
function DecoratorOpened:new(args)
  Decorator.new(self, {
    explorer       = args.explorer,
    enabled        = true,
    hl_pos         = args.explorer.opts.renderer.highlight_opened_files or "none",
    icon_placement = "none",
  })
end

---Opened highlight: renderer.highlight_opened_files and node has an open buffer
---@param node Node
---@return string|nil group
function DecoratorOpened:calculate_highlight(node)
  if self.range ~= "none" and buffers.is_opened(node) then
    return "NvimTreeOpenedHL"
  end
end

return DecoratorOpened
