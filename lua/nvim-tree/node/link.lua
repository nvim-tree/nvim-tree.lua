local api = require("nvim-tree.api")
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

---api node constructor
---@param node LinkNode
function api.LinkNode:new(node)
  if not node then
    return
  end

  self.link_to = node.link_to
  self.fs_stat_target = node.fs_stat_target
end

return LinkNode
