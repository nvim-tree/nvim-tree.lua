local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) RootNode: DirectoryNode
local RootNode = DirectoryNode:new()

---Static factory method
---@param explorer Explorer
---@param absolute_path string
---@param name string
---@param fs_stat uv.fs_stat.result|nil
---@return RootNode
function RootNode:create(explorer, absolute_path, name, fs_stat)
  local o = DirectoryNode:create(explorer, nil, absolute_path, name, fs_stat)

  o = self:new(o)

  return o
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
