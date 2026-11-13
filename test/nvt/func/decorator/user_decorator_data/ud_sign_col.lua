---@class (exact) UserDecoratorSignCol: nvim_tree.api.Decorator
---@field private my_icon1 nvim_tree.api.highlighted_string
local UserDecoratorSignCol = require("nvim-tree.api").Decorator:extend()

function UserDecoratorSignCol:new()
  self.enabled        = true
  self.icon_placement = "signcolumn"
  self.my_icon1       = { str = "1", hl = { "UDIcon1" } }

  self:define_sign(self.my_icon1)
end

---@param node nvim_tree.api.Node
---@return nvim_tree.api.highlighted_string[]? icons `nil` or empty table for no icons. Only the first glyph of {str} is used when {icon_placement} is `"signcolumn"`
function UserDecoratorSignCol:icons(node)
  if node.name:match(".*decorator.*") then
    return { self.my_icon1, }
  else
    return nil
  end
end

return UserDecoratorSignCol
