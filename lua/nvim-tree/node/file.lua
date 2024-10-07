local utils = require("nvim-tree.utils")

local BaseNode = require("nvim-tree.node")

---@class (exact) FileNode: BaseNode
---@field extension string
local FileNode = BaseNode:new()

---Static factory method
---@param explorer Explorer
---@param parent Node
---@param absolute_path string
---@param name string
---@param fs_stat uv.fs_stat.result?
---@return FileNode
function FileNode:create(explorer, parent, absolute_path, name, fs_stat)
  ---@type FileNode
  local o = {
    type = "file",
    explorer = explorer,
    absolute_path = absolute_path,
    executable = utils.is_executable(absolute_path),
    fs_stat = fs_stat,
    git_status = nil,
    hidden = false,
    is_dot = false,
    name = name,
    parent = parent,
    watcher = nil,
    diag_status = nil,

    extension = string.match(name, ".?[^.]+%.(.*)") or "",
  }
  o = self:new(o) --[[@as FileNode]]

  return o
end

---Create a sanitized partial copy of a node, populating children recursively.
---@return FileNode cloned
function FileNode:clone()
  local clone = BaseNode.clone(self) --[[@as FileNode]]

  clone.extension = self.extension

  return clone
end

return FileNode
