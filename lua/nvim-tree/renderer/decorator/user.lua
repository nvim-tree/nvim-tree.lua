local Decorator = require("nvim-tree.renderer.decorator")

---Exposed as nvim_tree.api.decorator.BaseDecorator
---@class (exact) DecoratorUser: Decorator
local DecoratorUser = Decorator:extend()

return DecoratorUser
