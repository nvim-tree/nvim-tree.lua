---@class (exact) UserDecoratorInline: nvim_tree.api.Decorator
local UserDecoratorInline = require("nvim-tree.api").Decorator:extend()

function UserDecoratorInline:new()
  self.enabled         = true
  self.highlight_range = "name"
  self.icon_placement  = "after"
end

---@param node nvim_tree.api.Node
---@return nvim_tree.api.highlighted_string? icon `nil` for no override
function UserDecoratorInline:icon_node(node)
  if node.name:match(".*decorator.*") then
    return { str = "N", hl = { "UDIconNode" } }
  else
    return nil
  end
end

---@param node nvim_tree.api.Node
---@return nvim_tree.api.highlighted_string[]? icons `nil` or empty table for no icons. Only the first glyph of {str} is used when {icon_placement} is `"signcolumn"`
function UserDecoratorInline:icons(node)
  if node.name:match(".*decorator.*") then
    return { { str = "1", hl = { "UDIcon1" } }, { str = "2", hl = { "UDIcon2" } } }
  else
    return nil
  end
end

---@param node nvim_tree.api.Node
---@return string? highlight group name `nil` when no highlighting to apply to the node
function UserDecoratorInline:highlight_group(node)
  if node.name:match(".*decorator.*") then
    return "UDName"
  else
    return nil
  end
end

return UserDecoratorInline
