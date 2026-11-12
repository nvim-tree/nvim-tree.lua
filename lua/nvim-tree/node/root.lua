local api = require("nvim-tree.api")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) RootNode: DirectoryNode
local RootNode = DirectoryNode:extend()

---@class RootNode
---@overload fun(args: NodeArgs): RootNode

---@protected
---@param args NodeArgs
function RootNode:new(args)
  RootNode.super.new(self, args)

  self.api_node_class = api.RootNode
end

---api node constructor
---@param api_node_uid_map? ApiNodeUidMap
---@param node RootNode
function api.RootNode:new(node, api_node_uid_map)
  if not node then
    return
  end

  api.RootNode.super.new(self, node, api_node_uid_map)
end

---Root is never a dotfile
---@return boolean
function RootNode:is_dotfile()
  return false
end

function RootNode:destroy()
  DirectoryNode.destroy(self)
end

return RootNode
