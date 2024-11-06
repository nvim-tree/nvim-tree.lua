local Object = require("nvim-tree.classic")

---@class (exact) LinkNode: Object
---@field link_to string
---@field protected fs_stat_target uv.fs_stat.result
local LinkNode = Object:extend()

---@class (exact) LinkNodeArgs: NodeArgs
---@field link_to string
---@field fs_stat_target uv.fs_stat.result
---
---@protected
---@param args LinkNodeArgs
function LinkNode:new(args)
  LinkNode.super.new(self, args)

  self.link_to = args.link_to
  self.fs_stat_target = args.fs_stat_target
end

return LinkNode
