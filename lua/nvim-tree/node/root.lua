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

return RootNode
