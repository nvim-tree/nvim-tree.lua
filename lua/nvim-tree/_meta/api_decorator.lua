---@meta
error("Cannot require a meta file")

local nvim_tree = { api = { decorator = { DecoratorUser = {} } } }

---Custom decorator
---It may:
---  Add icons
---  Set highlight group for the name or icons
---  Override node icon
---Register it via  :help nvim-tree.renderer.decorators
---Create class via require("nvim-tree.api").decorator.DecoratorUser:extend()
---Mandatory constructor  :new()  will be called once per tree render, with no arguments.
---Constructor must call:
---  :init
---  :define_sign when using "signcolumn" range

---Highlight group range as per nvim-tree.renderer.highlight_*
---@alias nvim_tree.api.decorator.HighlightRange "none" | "icon" | "name" | "all"

---Icon position as per renderer.icons.*_placement
---@alias nvim_tree.api.decorator.IconPlacement "none" | "before" | "after" | "signcolumn" | "right_align"

---Names of builtin decorators or your decorator classes. Builtins are ordered lowest to highest priority.
---@alias nvim_tree.api.decorator.Name "Git" | "Opened" | "Hidden" | "Modified" | "Bookmarks" | "Diagnostics" | "Copied" | "Cut" | nvim_tree.api.decorator.DecoratorUser

---Your decorator will extend this class via require("nvim-tree.api").decorator.DecoratorUser:extend()
---
---@class (exact) nvim_tree.api.decorator.DecoratorUser
---@field protected enabled boolean
---@field protected highlight_range nvim_tree.api.decorator.HighlightRange
---@field protected icon_placement nvim_tree.api.decorator.IconPlacement

---Abstract: no-args constructor must be implemented.
---
function nvim_tree.api.decorator.DecoratorUser:new() end

---Abstract: optionally implement to set the node's icon
---
---@param node nvim_tree.api.Node
---@return HighlightedString? icon_node
function nvim_tree.api.decorator.DecoratorUser:icon_node(node) end

---Abstract: optionally implement to provide icons and the highlight groups for your icon_placement.
---
---@param node nvim_tree.api.Node
---@return HighlightedString[]? icons
function nvim_tree.api.decorator.DecoratorUser:icons(node) end

---Abstract: optionally implement to provide one highlight group to apply to your highlight_range.
---
---@param node nvim_tree.api.Node
---@return string? highlight_group
function nvim_tree.api.decorator.DecoratorUser:highlight_group(node) end

---Must be called from your constructor.
---
---@class (exact) nvim_tree.api.decorator.InitArgs
---@field enabled boolean
---@field highlight_range nvim_tree.api.decorator.HighlightRange
---@field icon_placement nvim_tree.api.decorator.IconPlacement
---
---@protected
---@param args nvim_tree.api.decorator.InitArgs
function nvim_tree.api.decorator.DecoratorUser:init(args) end

---Define a sign. This should be called in the constructor.
---
---@protected
---@param icon HighlightedString?
function nvim_tree.api.decorator.DecoratorUser:define_sign(icon) end


--
-- Example Decorator
--

---@class (exact) MyDecorator: nvim_tree.api.decorator.DecoratorUser
---@field private my_icon nvim_tree.api.HighlightedString
local MyDecorator = require("nvim-tree.api").decorator.DecoratorUser:extend()

---Mandatory constructor  :new()  will be called once per tree render, with no arguments.
function MyDecorator:new()
  ---@type nvim_tree.api.decorator.InitArgs
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
