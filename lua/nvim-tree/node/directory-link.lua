local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) DirectoryLinkNode: DirectoryNode
---@field link_to string absolute path
---@field private fs_stat_target uv.fs_stat.result
local DirectoryLinkNode = DirectoryNode:new()

---Static factory method
---@param explorer Explorer
---@param parent DirectoryNode
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

function DirectoryLinkNode:destroy()
  DirectoryNode.destroy(self)
end

---Update the directory GitStatus of link target and the file status of the link itself
---@param parent_ignored boolean
---@param status table|nil
function DirectoryLinkNode:update_git_status(parent_ignored, status)
  if parent_ignored then
    self.git_status = {}
    self.git_status.file = "!!"
  elseif status then
    self.git_status = {}
    self.git_status.file = status.files and (status.files[self.link_to] or status.files[self.absolute_path])
    if status.dirs then
      self.git_status.dir = {}
      self.git_status.dir.direct = status.dirs.direct and status.dirs.direct[self.absolute_path]
      self.git_status.dir.indirect = status.dirs.indirect and status.dirs.indirect[self.absolute_path]
    end
  else
    self.git_status = nil
  end
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
