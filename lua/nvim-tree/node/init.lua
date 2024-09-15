---@class (exact) BaseNode
---@field type NODE_TYPE
---@field explorer Explorer
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.fs_stat.result|nil
---@field git_status GitStatus|nil
---@field hidden boolean
---@field is_dot boolean
---@field name string
---@field parent DirectoryNode
---@field watcher Watcher|nil
---@field diag_status DiagStatus|nil
local BaseNode = {}

---@alias Node DirectoryNode|FileNode|LinkNode|Explorer

---@param o BaseNode|nil
---@return BaseNode
function BaseNode:new(o)
  o = o or {}

  setmetatable(o, { __index = self })

  return o
end

function BaseNode:destroy()
  if self.watcher then
    self.watcher:destroy()
    self.watcher = nil
  end
end

---@return boolean
function BaseNode:has_one_child_folder()
  return #self.nodes == 1 and self.nodes[1].nodes and vim.loop.fs_access(self.nodes[1].absolute_path, "R") or false
end

---@return boolean
function BaseNode:is_git_ignored()
  return self.git_status ~= nil and self.git_status.file == "!!"
end

---@return boolean
function BaseNode:is_dotfile()
  if
    self.is_dot                                     --
    or (self.name and (self.name:sub(1, 1) == ".")) --
    or (self.parent and self.parent:is_dotfile())
  then
    self.is_dot = true
    return true
  end
  return false
end

return BaseNode
