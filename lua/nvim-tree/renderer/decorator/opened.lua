local buffers = require("nvim-tree.buffers")

local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) OpenDecorator: Decorator
---@field private explorer Explorer
---@field private icon? nvim_tree.api.highlighted_string
local OpenDecorator = Decorator:extend()

---@class OpenDecorator
---@overload fun(args: DecoratorArgs): OpenDecorator

---@protected
---@param args DecoratorArgs
function OpenDecorator:new(args)
  self.explorer        = args.explorer

  self.enabled         = true
  self.highlight_range = self.explorer.opts.renderer.highlight_opened_files or "none"
  self.icon_placement  = "none"
end

---Opened highlight: renderer.highlight_opened_files and node has an open buffer
---@param node Node
---@return string? highlight_group
function OpenDecorator:highlight_group(node)
  if self.highlight_range ~= "none" and buffers.is_opened(node) then
    return "NvimTreeOpenedHL"
  end
end

return OpenDecorator
