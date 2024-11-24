local Decorator = require("nvim-tree.renderer.decorator")

---Define a Decorator to optionally set:
---  Additional icons
---  Highlight group
---  Node icon
---Mandator constructor  MyDecorator:new()  will be called once per tree render, with no arguments.
---Must call:
---  super passing DecoratorArgs  MyDecorator.super.new(self, args)
---  define_sign when using "signcolumn"

---@class (exact) UserDecorator: Decorator
local UserDecorator = Decorator:extend()

---Override this method to set the node's icon
---@param node nvim_tree.api.Node
---@return HighlightedString? icon_node
function UserDecorator:icon_node(node)
  return self:nop(node)
end

---Override this method to provide icons and the highlight groups to apply to DecoratorIconPlacement
---@param node nvim_tree.api.Node
---@return HighlightedString[]? icons
function UserDecorator:icons(node)
  self:nop(node)
end

---Override this method to provide one highlight group to apply to DecoratorRange
---@param node nvim_tree.api.Node
---@return string? highlight_group
function UserDecorator:highlight_group(node)
  self:nop(node)
end

return UserDecorator
