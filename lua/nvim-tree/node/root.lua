local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) RootNode: DirectoryNode
local RootNode = DirectoryNode:extend()

---@param explorer Explorer
---@param absolute_path string
---@param name string
---@param fs_stat uv.fs_stat.result|nil
function RootNode:new(explorer, absolute_path, name, fs_stat)
  RootNode.super.new(self, explorer, nil, absolute_path, name, fs_stat)
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
