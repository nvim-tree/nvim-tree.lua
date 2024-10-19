local git = require("nvim-tree.git")

local Class = require("nvim-tree.class")

---TODO #2886
---TODO remove all @cast
---TODO remove all references to directory fields:

---Abstract Node class.
---Uses the abstract factory pattern to instantiate child instances.
---@class (exact) BaseNode: Class
---@field type NODE_TYPE
---@field explorer Explorer
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.fs_stat.result?
---@field git_status GitStatus?
---@field hidden boolean
---@field name string
---@field parent Node?
---@field watcher Watcher?
---@field diag_status DiagStatus?
---@field is_dot boolean cached is_dotfile
local BaseNode = Class:new()

---@alias Node RootNode|BaseNode|DirectoryNode|FileNode|DirectoryLinkNode|FileLinkNode

function BaseNode:destroy()
  if self.watcher then
    self.watcher:destroy()
    self.watcher = nil
  end
end

--luacheck: push ignore 212
---Update the GitStatus of the node
---@param parent_ignored boolean
---@param status table?
function BaseNode:update_git_status(parent_ignored, status) ---@diagnostic disable-line: unused-local
end

--luacheck: pop

---@return GitStatus?
function BaseNode:get_git_status()
end

---@param projects table
function BaseNode:reload_node_status(projects)
  local toplevel = git.get_toplevel(self.absolute_path)
  local status = projects[toplevel] or {}
  for _, node in ipairs(self.nodes) do
    node:update_git_status(self:is_git_ignored(), status)
    if node.nodes and #node.nodes > 0 then
      node:reload_node_status(projects)
    end
  end
end

---@return boolean
function BaseNode:is_git_ignored()
  return self.git_status ~= nil and self.git_status.file == "!!"
end

---Node or one of its parents begins with a dot
---@return boolean
function BaseNode:is_dotfile()
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

---Return self, should only be called on a DirectoryNode
---TODO #2886 remove method or leave in place, warn if practical and non too intrusive
---@return Node
function BaseNode:last_group_node()
  error(string.format("\nBaseNode:last_group_node called for '%s'", self.absolute_path))
  return self
end

---@param project table?
---@param root string?
function BaseNode:update_parent_statuses(project, root)
  local node = self
  while project and node do
    -- step up to the containing project
    if node.absolute_path == root then
      -- stop at the top of the tree
      if not node.parent then
        break
      end

      root = git.get_toplevel(node.parent.absolute_path)

      -- stop when no more projects
      if not root then
        break
      end

      -- update the containing project
      project = git.get_project(root)
      git.reload_project(root, node.absolute_path, nil)
    end

    -- update status
    node:update_git_status(node.parent and node.parent:is_git_ignored() or false, project)

    -- maybe parent
    node = node.parent
  end
end

---Get the highest parent of grouped nodes or the node itself
---@return Node
function BaseNode:group_parent_or_node()
  if self.parent and self.parent.group_next then
    return self.parent:group_parent_or_node()
  else
    return self
  end
end

---Create a sanitized partial copy of a node, populating children recursively.
---@return BaseNode cloned
function BaseNode:clone()
  ---@type Explorer
  local explorer_placeholder = nil

  ---@type BaseNode
  local clone = {
    type = self.type,
    explorer = explorer_placeholder,
    absolute_path = self.absolute_path,
    executable = self.executable,
    fs_stat = self.fs_stat,
    git_status = self.git_status,
    hidden = self.hidden,
    is_dot = self.is_dot,
    name = self.name,
    parent = nil,
    watcher = nil,
    diag_status = nil,
  }

  return clone
end

return BaseNode
