---@meta
error("Cannot require a meta file")

local nvim_tree = { api = { decorator = {} } }

---Highlight group range as per nvim-tree.renderer.highlight_*
---@alias nvim_tree.api.decorator.HighlightRange "none" | "icon" | "name" | "all"

---Icon position as per renderer.icons.*_placement
---@alias nvim_tree.api.decorator.IconPlacement "none" | "before" | "after" | "signcolumn" | "right_align"

---Names of builtin decorators or your decorator classes. Builtins are ordered lowest to highest priority.
---@alias nvim_tree.api.decorator.Name "Git" | "Opened" | "Hidden" | "Modified" | "Bookmarks" | "Diagnostics" | "Copied" | "Cut" | nvim_tree.api.decorator.UserDecorator

---A string for rendering, with optional highlight groups to apply to it
---@class (exact) nvim_tree.api.HighlightedString
---@field str string
---@field hl string[]

---Custom decorator, see :help nvim-tree-decorators
---
---@class (exact) nvim_tree.api.decorator.UserDecorator
---@field protected enabled boolean
---@field protected highlight_range nvim_tree.api.decorator.HighlightRange
---@field protected icon_placement nvim_tree.api.decorator.IconPlacement
nvim_tree.api.decorator.UserDecorator = {}

---Create your decorator class
---
function nvim_tree.api.decorator.UserDecorator:extend() end

---Abstract: no-args constructor must be implemented and will be called once per tree render.
---Must set all fields.
---
function nvim_tree.api.decorator.UserDecorator:new() end

---Abstract: optionally implement to set the node's icon
---
---@param node nvim_tree.api.Node
---@return nvim_tree.api.HighlightedString? icon_node
function nvim_tree.api.decorator.UserDecorator:icon_node(node) end

---Abstract: optionally implement to provide icons and the highlight groups for your icon_placement.
---
---@param node nvim_tree.api.Node
---@return nvim_tree.api.HighlightedString[]? icons
function nvim_tree.api.decorator.UserDecorator:icons(node) end

---Abstract: optionally implement to provide one highlight group to apply to your highlight_range.
---
---@param node nvim_tree.api.Node
---@return string? highlight_group
function nvim_tree.api.decorator.UserDecorator:highlight_group(node) end

---Define a sign. This should be called in the constructor.
---
---@protected
---@param icon nvim_tree.api.HighlightedString?
function nvim_tree.api.decorator.UserDecorator:define_sign(icon) end
