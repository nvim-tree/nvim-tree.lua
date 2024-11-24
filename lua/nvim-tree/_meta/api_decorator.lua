---@meta
error('Cannot require a meta file')

---Highlight group range as per nvim-tree.renderer.highlight_*
---@alias nvim_tree.api.decorator.HighlightRange "none" | "icon" | "name" | "all"

---Icon position as per renderer.icons.*_placement
---@alias nvim_tree.api.decorator.IconPlacement "none" | "before" | "after" | "signcolumn" | "right_align"

---UserDecorator Constructor Arguments
---@class (exact) nvim_tree.api.decorator.UserDecoratorArgs
---@field enabled boolean
---@field highlight_range nvim_tree.api.decorator.HighlightRange
---@field icon_placement nvim_tree.api.decorator.IconPlacement


--
-- Example UserDecorator
--

local UserDecorator = require("nvim-tree.renderer.decorator.user")

---@class (exact) MyDecorator: UserDecorator
---@field private my_icon nvim_tree.api.HighlightedString
local MyDecorator = UserDecorator:extend()

---Constructor
function MyDecorator:new()

  ---@type nvim_tree.api.decorator.UserDecoratorArgs
  local args = {
    enabled         = true,
    highlight_range = "all",
    icon_placement  = "signcolumn",
  }

  -- construct super with args
  MyDecorator.super.new(self, args)

  -- create your icon once, for convenience
  self.my_icon = { str = "I", hl = { "MyIcon" } }

  -- Define the icon sign only once
  -- Only needed if you are using icon_placement = "signcolumn"
  self:define_sign(self.my_icon)
end

---Overridde node icon
---@param node nvim_tree.api.Node
---@return nvim_tree.api.HighlightedString? icon_node
function MyDecorator:icon_node(node)
  if node.name == "example" then
    return self.my_icon
  else
    return nil
  end
end

---Return one icon for DecoratorIconPlacement
---@param node nvim_tree.api.Node
---@return nvim_tree.api.HighlightedString[]? icons
function MyDecorator:icons(node)
  if node.name == "example" then
    return { self.my_icon }
  else
    return nil
  end
end

---Exactly one highlight group for DecoratorHighlightRange
---@param node nvim_tree.api.Node
---@return string? highlight_group
function MyDecorator:highlight_group(node)
  if node.name == "example" then
    return "MyHighlight"
  else
    return nil
  end
end

return MyDecorator

--
-- Internal Aliases
--
---@alias DecoratorHighlightRange nvim_tree.api.decorator.HighlightRange
---@alias DecoratorIconPlacement nvim_tree.api.decorator.IconPlacement

