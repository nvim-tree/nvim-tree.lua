local git_utils = require("nvim-tree.git.utils")

local FileNode = require("nvim-tree.node.file")

---@class (exact) FileLinkNode: FileNode
---@field link_to string absolute path
---@field fs_stat_target uv.fs_stat.result
local FileLinkNode = FileNode:new()

---Static factory method
---@param explorer Explorer
---@param parent DirectoryNode
---@param absolute_path string
---@param link_to string
---@param name string
---@param fs_stat uv.fs_stat.result?
---@param fs_stat_target uv.fs_stat.result
---@return FileLinkNode? nil on vim.loop.fs_realpath failure
function FileLinkNode:create(explorer, parent, absolute_path, link_to, name, fs_stat, fs_stat_target)
  local o = FileNode:create(explorer, parent, absolute_path, name, fs_stat)

  o = self:new(o) --[[@as FileLinkNode]]

  o.type = "link"
  o.link_to = link_to
  o.fs_stat_target = fs_stat_target

  return o
end

function FileLinkNode:destroy()
  FileNode.destroy(self)
end

-----Update the GitStatus of the target otherwise the link itself
-----@param parent_ignored boolean
-----@param status table|nil
function FileLinkNode:update_git_status(parent_ignored, status)
  self.git_status = git_utils.git_status_file(parent_ignored, status, self.link_to, self.absolute_path)
end

---Create a sanitized partial copy of a node
---@return FileLinkNode cloned
function FileLinkNode:clone()
  local clone = FileNode.clone(self) --[[@as FileLinkNode]]

  clone.type = self.type
  clone.link_to = self.link_to
  clone.fs_stat_target = self.fs_stat_target

  return clone
end

return FileLinkNode
