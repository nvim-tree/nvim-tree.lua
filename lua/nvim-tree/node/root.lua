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

  o = self:new(o) --[[@as RootNode]]

  return o
end

return RootNode
