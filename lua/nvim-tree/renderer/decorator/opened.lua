local buffers = require("nvim-tree.buffers")

local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorOpened: Decorator
---@field private explorer Explorer
---@field private icon HighlightedString|nil
local DecoratorOpened = Decorator:extend()

---@class DecoratorOpened
---@overload fun(explorer: Explorer): DecoratorOpened

---@protected
---@param explorer Explorer
function DecoratorOpened:new(explorer)
  self.explorer = explorer

  ---@type DecoratorArgs
  local args = {
    enabled         = true,
    highlight_range = self.explorer.opts.renderer.highlight_opened_files or "none",
    icon_placement  = "none",
  }

  DecoratorOpened.super.new(self, args)
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
