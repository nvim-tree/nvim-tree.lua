local Decorator = require("nvim-tree.renderer.decorator")

---Define a Decorator to optionally set:
---  Additional icons
---  Highlight group
---  Node icon
---Mandator constructor  MyDecorator:new()  will be called once per tree render, with no arguments.
---Must call:
---  super passing DecoratorArgs  MyDecorator.super.new(self, args)
---  define_sign when using "signcolumn"
---See example at end.

---@class (exact) UserDecorator: Decorator
local UserDecorator = Decorator:extend()

---Override this method to provide icons and the highlight groups to apply to DecoratorIconPlacement
---@param node Node
---@return HighlightedString[]? icons
function UserDecorator:icons(node)
  self:nop(node)
end

---Override this method to provide one highlight group to apply to DecoratorRange
---@param node Node
---@return string? group
function UserDecorator:highlight_group(node)
  self:nop(node)
end

return UserDecorator


---
---Example user decorator
--[[

local UserDecorator = require("nvim-tree.renderer.decorator.user")

---@class (exact) MyDecorator: UserDecorator
---@field private my_icon HighlightedString
local MyDecorator = UserDecorator:extend()

---Constructor
function MyDecorator:new()

  ---@type DecoratorArgs
  local args = {
    enabled         = true,
    highlight_range = "all",
    icon_placement  = "signcolumn",
  }

  MyDecorator.super.new(self, args)

  -- create your icon once, for convenience
  self.my_icon = { str = "I", hl = { "MyIcon" } }

  -- Define the icon sign only once
  -- Only needed if you are using icon_placement = "signcolumn"
  self:define_sign(self.my_icon)
end

---Just one icon for DecoratorIconPlacement
---@param node Node
---@return HighlightedString[]|nil icons
function MyDecorator:icons(node)
  if node.name == "example" then
    return { self.my_icon }
  else
    return nil
  end
end

---Exactly one highlight group for DecoratorHighlightRange
---@param node Node
---@return string|nil group
function MyDecorator:highlight_group(node)
  if node.name == "example" then
    return "ExampleHighlight"
  else
    return nil
  end
end

--]]
