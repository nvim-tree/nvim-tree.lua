local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) UserDecorator: Decorator
local UserDecorator = Decorator:extend()

---@param node nvim_tree.api.Node
---@return HighlightedString? icon_node
function UserDecorator:icon_node(node)
  return self:nop(node)
end

---@param node nvim_tree.api.Node
---@return HighlightedString[]? icons
function UserDecorator:icons(node)
  self:nop(node)
end

---@param node nvim_tree.api.Node
---@return string? highlight_group
function UserDecorator:highlight_group(node)
  self:nop(node)
end

return UserDecorator
