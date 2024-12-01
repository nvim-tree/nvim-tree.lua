local Decorator = require("nvim-tree.renderer.decorator")

---Exposed as nvim_tree.api.decorator.UserDecorator
---@class (exact) UserDecorator: Decorator
local UserDecorator = Decorator:extend()

return UserDecorator
