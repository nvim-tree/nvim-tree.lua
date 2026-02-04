local Decorator = require("nvim-tree.renderer.decorator")

---Abstract builtin decorator
---Overrides all methods to use a Node instead of nvim_tree.api.Node as we don't have generics.
---
---@class (exact) BuiltinDecorator: Decorator
---
---@field protected explorer Explorer
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

---@class (exact) BuiltinDecoratorArgs
---@field explorer Explorer

---@protected
---@param args BuiltinDecoratorArgs
function BuiltinDecorator:new(args)
  self.explorer = args.explorer
end

return BuiltinDecorator
