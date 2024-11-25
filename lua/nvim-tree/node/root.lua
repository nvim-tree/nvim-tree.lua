local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) RootNode: DirectoryNode
local RootNode = DirectoryNode:extend()

---@class RootNode
---@overload fun(args: NodeArgs): RootNode

---@protected
---@param args NodeArgs
function RootNode:new(args)
  RootNode.super.new(self, args)
end

---Root is never a dotfile
---@return boolean
function RootNode:is_dotfile()
  return false
end

function RootNode:destroy()
  DirectoryNode.destroy(self)
end

---Create a sanitized partial copy of a node, populating children recursively.
---@param api_nodes table<number, nvim_tree.api.Node>? optional map of uids to api node to populate
---@return nvim_tree.api.RootNode cloned
function RootNode:clone(api_nodes)
  local clone = DirectoryNode.clone(self, api_nodes) --[[@as nvim_tree.api.RootNode]]

  return clone
end

return RootNode
