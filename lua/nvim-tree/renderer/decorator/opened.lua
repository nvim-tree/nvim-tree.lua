local buffers = require("nvim-tree.buffers")

local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorOpened: Decorator
---@field private explorer Explorer
---@field private icon HighlightedString|nil
local DecoratorOpened = Decorator:extend()
DecoratorOpened.name = "Opened"

---@class DecoratorOpened
---@overload fun(explorer: Explorer): DecoratorOpened

---@protected
---@param args DecoratorArgs
function DecoratorOpened:new(args)
  self.explorer = args.explorer

  ---@type AbstractDecoratorArgs
  local a = {
    enabled         = true,
    highlight_range = self.explorer.opts.renderer.highlight_opened_files or "none",
    icon_placement  = "none",
  }

  DecoratorOpened.super.new(self, a)
end

---Opened highlight: renderer.highlight_opened_files and node has an open buffer
---@param node Node
---@return string? highlight_group
function DecoratorOpened:highlight_group(node)
  if self.highlight_range ~= "none" and buffers.is_opened(node) then
    return "NvimTreeOpenedHL"
  end
end

return DecoratorOpened
