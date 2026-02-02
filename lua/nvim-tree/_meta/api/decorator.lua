---@meta

---@brief
---Highlighting and icons for nodes are provided by Decorators, see [nvim-tree-icons-highlighting]. You may provide your own in addition to the builtin decorators.
---
---Decorators may:
---- Add icons
---- Set highlight group for the name or icons
---- Override node icon
---
---To register your decorator:
---- Create a class that extends [nvim_tree.api.Decorator]
---- Register it by adding the class to [nvim_tree.config.renderer] {decorators}
---
---Your class must:
---- [nvim_tree.Class:extend()] the interface [nvim_tree.api.Decorator] 
---- Provide a no-arguments constructor [nvim_tree.Class:new()] that sets the mandatory fields:
---   - {enabled}
---   - {highlight_range}
---   - {icon_placement}
---
---Your class may:
---- Implement methods to provide decorations:
---   - [nvim_tree.api.Decorator:highlight_group()]
---   - [nvim_tree.api.Decorator:icon_node()]
---   - [nvim_tree.api.Decorator:icons()]
---
---Your class must:
---- Call [nvim_tree.api.Decorator:define_sign()] in your constructor if using `"signcolumn"` {icon_placement}

local nvim_tree = { api = {} }

local Class = require("nvim-tree.classic")

---
---Highlight group range as per nvim-tree.renderer.highlight_*
---
---@alias nvim_tree.api.decorator.highlight_range nvim_tree.config.renderer.highlight

---Icon position as per renderer.icons.*_placement
---
---@alias nvim_tree.api.decorator.icon_placement "none"|nvim_tree.config.renderer.icons.placement

---
---Names of builtin decorators or your decorator classes. Builtins are ordered lowest to highest priority.
---
---@alias nvim_tree.api.decorator.types nvim_tree.api.Decorator|"Git"|"Opened"|"Hidden"|"Modified"|"Bookmarks"|"Diagnostics"|"Copied"|"Cut"

---
---A string for rendering, with optional highlight groups to apply to it
---
---@class (exact) nvim_tree.api.decorator.highlighted_string
---@field str string
---@field hl string[]

---
---Abstract Decorator interface
---
---@class nvim_tree.api.Decorator: nvim_tree.Class
---@field enabled boolean
---@field highlight_range nvim_tree.api.decorator.highlight_range
---@field icon_placement nvim_tree.api.decorator.icon_placement
local Decorator = Class:extend()
nvim_tree.api.Decorator = Decorator

---
---Abstract: optionally implement to set the node's icon
---
---@param node nvim_tree.api.Node
---@return nvim_tree.api.decorator.highlighted_string? icon_node
function Decorator:icon_node(node) end

---
---Abstract: optionally implement to provide icons and the highlight groups for your icon_placement.
---
---@param node nvim_tree.api.Node
---@return nvim_tree.api.decorator.highlighted_string[]? icons
function Decorator:icons(node) end

---
---Abstract: optionally implement to provide one highlight group to apply to your highlight_range.
---
---@param node nvim_tree.api.Node
---@return string? highlight_group
function Decorator:highlight_group(node) end

---
---Defines a sign. This should be called in the constructor.
---
---@param icon nvim_tree.api.decorator.highlighted_string?
function Decorator:define_sign(icon) end

return nvim_tree.api.Decorator
