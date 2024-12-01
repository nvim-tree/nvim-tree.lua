local Decorator = require("nvim-tree.renderer.decorator")

---Exposed as nvim_tree.api.decorator.DecoratorUser
---@class (exact) DecoratorUser: Decorator
local DecoratorUser = Decorator:extend()

---User calls this instead of new
---@param args nvim_tree.api.decorator.InitArgs
function DecoratorUser:init(args)
  DecoratorUser.super.new(self, args)
end

return DecoratorUser
