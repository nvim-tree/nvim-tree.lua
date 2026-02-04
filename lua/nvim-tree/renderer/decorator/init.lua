local UserDecorator = require("nvim-tree.renderer.decorator.user")

---Builtin decorator interface.
---Overrides all methods to use a Node instead of nvim_tree.api.Node as we don't have generics.
---
---@class (exact) Decorator: UserDecorator
---
---@field protected enabled boolean
---@field protected highlight_range nvim_tree.config.renderer.highlight
---@field protected icon_placement "none"|nvim_tree.config.renderer.icons.placement
---
---@field icon_node                 fun(self: Decorator, node: Node): nvim_tree.api.highlighted_string?
---@field icons                     fun(self: Decorator, node: Node): nvim_tree.api.highlighted_string?
---@field highlight_group           fun(self: Decorator, node: Node): string?
---@field highlight_group_icon_name fun(self: Decorator, node: Node): string?, string?
---@field sign_name                 fun(self: Decorator, node: Node): string?
---@field icons_before              fun(self: Decorator, node: Node): nvim_tree.api.highlighted_string[]?
---@field icons_after               fun(self: Decorator, node: Node): nvim_tree.api.highlighted_string[]?
---@field icons_right_align         fun(self: Decorator, node: Node): nvim_tree.api.highlighted_string[]?
local Decorator = UserDecorator:extend()

---TODO #3241 create an internal decorator class with explorer member and lose the UserDecorator
---@class (exact) DecoratorArgs
---@field explorer Explorer

return Decorator
