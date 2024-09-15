local utils = require("nvim-tree.utils")

local BaseNode = require("nvim-tree.node.init")

---@class (exact) FileNode: BaseNode
---@field extension string
local FileNode = BaseNode:new()

---@param explorer Explorer
-----@param parent DirectoryNode    -- TODO
---@param absolute_path string
---@param name string
---@param fs_stat uv.fs_stat.result|nil
---@return FileNode
function FileNode:new(explorer, parent, absolute_path, name, fs_stat)
  local o = BaseNode.new(self, {
    type = "file",
    explorer = explorer,
    absolute_path = absolute_path,
    executable = utils.is_executable(absolute_path),
    fs_stat = fs_stat,
    name = name,
    parent = parent,
    hidden = false,
    is_dot = false,

    extension = string.match(name, ".?[^.]+%.(.*)") or "",
  })
  ---@cast o FileNode

  return o
end

return FileNode
