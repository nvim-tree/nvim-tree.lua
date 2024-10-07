local git = require("nvim-tree.git")

local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) DirectoryLinkNode: DirectoryNode
---@field link_to string absolute path
---@field fs_stat_target uv.fs_stat.result
local DirectoryLinkNode = DirectoryNode:new()

---Static factory method
---@param explorer Explorer
---@param parent Node
---@param absolute_path string
---@param link_to string
---@param name string
---@param fs_stat uv.fs_stat.result?
---@param fs_stat_target uv.fs_stat.result
---@return DirectoryLinkNode? nil on vim.loop.fs_realpath failure
function DirectoryLinkNode:create(explorer, parent, absolute_path, link_to, name, fs_stat, fs_stat_target)
  -- create DirectoryNode with the target path for the watcher
  local o = DirectoryNode:create(explorer, parent, link_to, name, fs_stat)

  o = self:new(o) --[[@as DirectoryLinkNode]]

  -- reset absolute path to the link itself
  o.absolute_path = absolute_path

  o.type = "link"
  o.link_to = link_to
  o.fs_stat_target = fs_stat_target

  return o
end

-----Update the GitStatus of link target
-----@param parent_ignored boolean
-----@param status table|nil
function DirectoryLinkNode:update_git_status(parent_ignored, status)
  self.git_status = git.git_status_dir(parent_ignored, status, self.link_to)
end

---Create a sanitized partial copy of a node, populating children recursively.
---@return DirectoryLinkNode cloned
function DirectoryLinkNode:clone()
  local clone = DirectoryNode.clone(self) --[[@as DirectoryLinkNode]]

  clone.type = self.type
  clone.link_to = self.link_to
  clone.fs_stat_target = self.fs_stat_target

  return clone
end

return DirectoryLinkNode
