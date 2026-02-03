---@meta

---#TODO 3241 maybe rename to UserDecorator

---@brief
---Highlighting and icons for nodes are provided by Decorators, see [nvim-tree-icons-highlighting] for an overview. You may provide your own in addition to the builtin decorators.
---
---Decorators are rendered in [nvim_tree.config.renderer] {decorators} order of precedence, with later decorators applying additively over earlier.
---
---Decorators may:
---- Add icons
---- Set a highlight group name for the name or icons
---- Override node icon
---
---To register your decorator:
---- Create a class that extends [nvim_tree.api.Decorator]
---- Register it by adding the class to [nvim_tree.config.renderer] {decorators}
---
---Your decorator will be constructed and executed each time the tree is rendered.
---
---Your class must:
---- [nvim_tree.Class:extend()] the interface [nvim_tree.api.Decorator]
---- Provide a no-arguments constructor [nvim_tree.Class:new()] that sets the mandatory fields:
---   - {enabled}
---   - {highlight_range}
---   - {icon_placement}
---- Call [nvim_tree.api.Decorator:define_sign()] in your constructor when {icon_placement} is `"signcolumn"`
---
---Your class may:
---- Implement methods to provide decorations:
---   - [nvim_tree.api.Decorator:highlight_group()]
---   - [nvim_tree.api.Decorator:icon_node()]
---   - [nvim_tree.api.Decorator:icons()]

local nvim_tree = { api = {} }

local Class = require("nvim-tree.classic")

---
---Text or glyphs with optional highlight group names to apply to it.
---
---@class nvim_tree.api.highlighted_string
---
---One or many glyphs/characters. 
---@field str string
---
---Highlight group names to apply in order. Empty table for no highlighting.
---@field hl string[]


---
---Decorator interface
---
---@class nvim_tree.api.Decorator: nvim_tree.Class
---
---Enable this decorator.
---@field enabled boolean
---
---What to highlight: [nvim_tree.config.renderer.highlight]
---@field highlight_range nvim_tree.config.renderer.highlight
---
---Where to place the icons: [nvim_tree.config.renderer.icons.placement]
---@field icon_placement "none"|nvim_tree.config.renderer.icons.placement
---
local Decorator = Class:extend()
nvim_tree.api.Decorator = Decorator

---
---Icon to override for the node.
---
---Abstract, optional to implement.
---
---@param node nvim_tree.api.Node
---@return nvim_tree.api.highlighted_string? icon `nil` for no override
function Decorator:icon_node(node) end

---
---Icons to add to the node as per {icon_placement}
---
---Abstract, optional to implement.
---
---@param node nvim_tree.api.Node
---@return nvim_tree.api.highlighted_string[]? icons `nil` or empty table for no icons. Only the first glyph of {str} is used when {icon_placement} is `"signcolumn"`
function Decorator:icons(node) end

---
---One highlight group that applies additively to the {node} name for {highlight_range}.
---
---Abstract, optional to implement.
---
---@param node nvim_tree.api.Node
---@return string? highlight group name `nil` when no highlighting to apply to the node
function Decorator:highlight_group(node) end

---
---Defines a sign for an icon. This is mandatory and necessary only when {icon_placement} is `"signcolumn"`
---
---This must be called during your constructor for all icons that you will return from [nvim_tree.api.Decorator:icons()]
---
---@param icon nvim_tree.api.highlighted_string? does nothing if nil
function Decorator:define_sign(icon) end

return nvim_tree.api.Decorator
