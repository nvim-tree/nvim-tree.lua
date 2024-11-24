---@meta
error('Cannot require a meta file')

local nvim_tree = { api = { decorator = { BaseDecorator = {} } } }

---Highlight group range as per nvim-tree.renderer.highlight_*
---@alias nvim_tree.api.decorator.HighlightRange "none" | "icon" | "name" | "all"

---Icon position as per renderer.icons.*_placement
---@alias nvim_tree.api.decorator.IconPlacement "none" | "before" | "after" | "signcolumn" | "right_align"

--
-- BaseDecorator Class, see example implementation below
--

---User defined decorator to optionally add:
---  Additional icons
---  Name highlight group
---  Node icon override
---Class must be created via nvim_tree.api.decorator.BaseDecorator:extend()
---Mandatory constructor  :new()  will be called once per tree render, with no arguments.
---Constructor must call:
---  .super.new(self, args)  passing nvim_tree.api.decorator.BaseDecoratorArgs
---  :define_sign(...)  when using "signcolumn" range
---@class (exact) nvim_tree.api.decorator.BaseDecorator
---@field protected enabled boolean
---@field protected highlight_range nvim_tree.api.decorator.HighlightRange
---@field protected icon_placement nvim_tree.api.decorator.IconPlacement

---Constructor Arguments
---@class (exact) nvim_tree.api.decorator.BaseDecoratorArgs
---@field enabled boolean
---@field highlight_range nvim_tree.api.decorator.HighlightRange
---@field icon_placement nvim_tree.api.decorator.IconPlacement

---Use to instantiate your decorator class
function nvim_tree.api.decorator.BaseDecorator:extend() end

---Super constructor must be called from your constructor
---BaseDecorator.super.new(self, args)
---@protected
---@param self nvim_tree.api.decorator.BaseDecorator your instance
---@param args nvim_tree.api.decorator.BaseDecoratorArgs
function nvim_tree.api.decorator.BaseDecorator.new(self, args) end

---Must implement a constructor and call super
function nvim_tree.api.decorator.BaseDecorator:new() end

---Implement this method to set the node's icon
---@param node nvim_tree.api.Node
---@return HighlightedString? icon_node
function nvim_tree.api.decorator.BaseDecorator:icon_node(node) end

---Implement this method to provide icons and the highlight groups to apply to IconPlacement
---@param node nvim_tree.api.Node
---@return HighlightedString[]? icons
function nvim_tree.api.decorator.BaseDecorator:icons(node) end

---Implement this method to provide one highlight group to apply to HighlightRange
---@param node nvim_tree.api.Node
---@return string? highlight_group
function nvim_tree.api.decorator.BaseDecorator:highlight_group(node) end


--
-- Example Decorator
--

local BaseDecorator = require("nvim-tree.api").decorator.BaseDecorator

---@class (exact) MyDecorator: nvim_tree.api.decorator.BaseDecorator
---@field private my_icon nvim_tree.api.HighlightedString
local MyDecorator = BaseDecorator:extend()

---Mandatory constructor  :new()  will be called once per tree render, with no arguments.
function MyDecorator:new()
  ----@type nvim_tree.api.decorator.BaseDecoratorArgs
  local args = {
    enabled         = true,
    highlight_range = "all",
    icon_placement  = "signcolumn",
  }

  -- construct super with args
  BaseDecorator.new(self, args)

  -- create your icon once, for convenience
  self.my_icon = { str = "I", hl = { "MyIcon" } }

  -- Define the icon sign only once
  -- Only needed if you are using icon_placement = "signcolumn"
  self:define_sign(self.my_icon)
end

---Override node icon
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
