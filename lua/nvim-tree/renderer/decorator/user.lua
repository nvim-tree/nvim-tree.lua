local Decorator = require("nvim-tree.renderer.decorator")

---Marker parent for user decorators
---@class (exact) UserDecorator: Decorator
local UserDecorator = Decorator:extend()

---@class UserDecorator
---@overload fun(args: DecoratorArgs): UserDecorator

---@protected
---@param args DecoratorArgs
function UserDecorator:new(args)
  UserDecorator.super.new(self, args)
end

return UserDecorator
