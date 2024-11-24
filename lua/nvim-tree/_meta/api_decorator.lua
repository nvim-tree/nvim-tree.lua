---@meta
error("Cannot require a meta file")

local nvim_tree = { api = { decorator = { AbstractDecorator = {} } } }

---Custom decorator extends nvim_tree.api.decorator.AbstractDecorator
---It may:
---  Add icons
---  Set name highlight group
---  Override node icon
---Class must be created via nvim_tree.api.decorator.create()
---Mandatory constructor  :new()  will be called once per tree render, with no arguments.
---Constructor must call:
---  :init
---  :define_sign when using "signcolumn" range

---Highlight group range as per nvim-tree.renderer.highlight_*
---@alias nvim_tree.api.decorator.HighlightRange "none" | "icon" | "name" | "all"

---Icon position as per renderer.icons.*_placement
---@alias nvim_tree.api.decorator.IconPlacement "none" | "before" | "after" | "signcolumn" | "right_align"

---Names of predefined decorators or your decorator classes
---@alias nvim_tree.api.decorator.Name "Cut" | "Copied" | "Diagnostics" | "Bookmarks" | "Modified" | "Hidden" | "Opened" | "Git" | nvim_tree.api.decorator.AbstractDecorator

---Abstract decorator class, your decorator will extend this
---
---@class (exact) nvim_tree.api.decorator.AbstractDecorator
---@field protected enabled boolean
---@field protected highlight_range nvim_tree.api.decorator.HighlightRange
---@field protected icon_placement nvim_tree.api.decorator.IconPlacement

---Abstract no-args constructor must be implemented
---
function nvim_tree.api.decorator.AbstractDecorator:new() end

---Must be called from your constructor
---
---@class (exact) nvim_tree.api.decorator.AbstractDecoratorInitArgs
---@field enabled boolean
---@field highlight_range nvim_tree.api.decorator.HighlightRange
---@field icon_placement nvim_tree.api.decorator.IconPlacement
---
---@protected
---@param args nvim_tree.api.decorator.AbstractDecoratorInitArgs
function nvim_tree.api.decorator.AbstractDecorator:init(args) end

---Abstract: optionally implement to set the node's icon
---
---@param node nvim_tree.api.Node
---@return HighlightedString? icon_node
function nvim_tree.api.decorator.AbstractDecorator:icon_node(node) end

---Abstract: optionally implement to provide icons and the highlight groups for your icon_placement
---
---@param node nvim_tree.api.Node
---@return HighlightedString[]? icons
function nvim_tree.api.decorator.AbstractDecorator:icons(node) end

---Abstract: optionally implement to provide one highlight group to apply to your highlight_range
---
---@param node nvim_tree.api.Node
---@return string? highlight_group
function nvim_tree.api.decorator.AbstractDecorator:highlight_group(node) end


--
-- Example Decorator
--

---@class (exact) MyDecorator: nvim_tree.api.decorator.AbstractDecorator
---@field private my_icon nvim_tree.api.HighlightedString
local MyDecorator = require("nvim-tree.api").decorator.create()

---Mandatory constructor  :new()  will be called once per tree render, with no arguments.
function MyDecorator:new()
  ---@type nvim_tree.api.decorator.AbstractDecoratorInitArgs
  local args = {
    enabled         = true,
    highlight_range = "all",
    icon_placement  = "signcolumn",
  }

  -- init
  self:init(args)

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
