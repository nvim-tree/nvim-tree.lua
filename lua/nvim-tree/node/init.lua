---@class ParentNode
---@field name string

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

return BaseNode
