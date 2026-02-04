local Decorator = require("nvim-tree.renderer.decorator")

---Builtin decorator interface.
---Overrides all methods to use a Node instead of nvim_tree.api.Node as we don't have generics.
---
---@class (exact) BuiltinDecorator: Decorator
---
---@field protected enabled boolean
---@field protected highlight_range nvim_tree.config.renderer.highlight
---@field protected icon_placement "none"|nvim_tree.config.renderer.icons.placement
---
---@field icon_node                 fun(self: BuiltinDecorator, node: Node): nvim_tree.api.highlighted_string?
---@field icons                     fun(self: BuiltinDecorator, node: Node): nvim_tree.api.highlighted_string?
---@field highlight_group           fun(self: BuiltinDecorator, node: Node): string?
---@field highlight_group_icon_name fun(self: BuiltinDecorator, node: Node): string?, string?
---@field sign_name                 fun(self: BuiltinDecorator, node: Node): string?
---@field icons_before              fun(self: BuiltinDecorator, node: Node): nvim_tree.api.highlighted_string[]?
---@field icons_after               fun(self: BuiltinDecorator, node: Node): nvim_tree.api.highlighted_string[]?
---@field icons_right_align         fun(self: BuiltinDecorator, node: Node): nvim_tree.api.highlighted_string[]?
local BuiltinDecorator = Decorator:extend()

---TODO #3241 create a common constructor
---@class (exact) BuiltinDecoratorArgs
---@field explorer Explorer

return BuiltinDecorator
