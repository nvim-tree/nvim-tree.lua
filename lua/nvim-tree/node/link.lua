local Class = require("nvim-tree.classic")

---@class (exact) LinkNode: nvim_tree.Class
---@field link_to string
---@field fs_stat_target uv.fs_stat.result
local LinkNode = Class:extend()

---@class (exact) LinkNodeArgs: NodeArgs
---@field link_to string
---@field fs_stat_target uv.fs_stat.result

---@protected
---@param args LinkNodeArgs
function LinkNode:new(args)
  self.link_to = args.link_to
  self.fs_stat_target = args.fs_stat_target
end

return LinkNode
