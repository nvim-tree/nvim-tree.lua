local Class = require("nvim-tree.class")

---Abstract Node class.
---Uses the abstract factory pattern to instantiate child instances.
---@class (exact) Node: Class
---@field type NODE_TYPE
---@field explorer Explorer
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.fs_stat.result?
---@field git_status GitNodeStatus?
---@field hidden boolean
---@field name string
---@field parent DirectoryNode?
---@field diag_status DiagStatus?
---@field private is_dot boolean cached is_dotfile
local Node = Class:new()

function Node:destroy()
end

---Update the GitStatus of the node
---Abstract
---@param parent_ignored boolean
---@param status table?
function Node:update_git_status(parent_ignored, status)
  self:nop(parent_ignored, status)
end

---@return string[]? xy short-format statuses
function Node:get_git_status()
end

---@return boolean
function Node:is_git_ignored()
  return self.git_status ~= nil and self.git_status.file == "!!"
end

---Node or one of its parents begins with a dot
---@return boolean
function Node:is_dotfile()
  if
    self.is_dot
    or (self.name and (self.name:sub(1, 1) == "."))
    or (self.parent and self.parent:is_dotfile())
  then
    self.is_dot = true
    return true
  end
  return false
end

---Get the highest parent of grouped nodes, nil when not grouped
---@return DirectoryNode?
function Node:get_parent_of_group()
  if not self.parent or not self.parent.group_next then
    return nil
  end

  local node = self.parent
  while node do
    if node.parent and node.parent.group_next then
      node = node.parent
    else
      return node
    end
  end
end

---Create a sanitized partial copy of a node, populating children recursively.
---@return Node cloned
function Node:clone()
  ---@type Explorer
  local explorer_placeholder = nil

  ---@type Node
  local clone = {
    type = self.type,
    explorer = explorer_placeholder,
    absolute_path = self.absolute_path,
    executable = self.executable,
    fs_stat = self.fs_stat,
    git_status = self.git_status,
    hidden = self.hidden,
    name = self.name,
    parent = nil,
    diag_status = nil,
    is_dot = self.is_dot,
  }

  return clone
end

return Node
