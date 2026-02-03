local Decorator = require("nvim-tree.renderer.decorator")

---Exposed as nvim_tree.api.Decorator
---@class (exact) UserDecorator: Decorator
local UserDecorator = Decorator:extend()

return UserDecorator
