local git = require("nvim-tree.git")
local utils = require("nvim-tree.utils")

local BaseNode = require("nvim-tree.node")

---@class (exact) FileNode: BaseNode
---@field extension string
local FileNode = BaseNode:new()

---Static factory method
---@param explorer Explorer
---@param parent DirectoryNode
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

---Update the GitStatus of the file
---@param parent_ignored boolean
---@param status table|nil
function FileNode:update_git_status(parent_ignored, status)
  self.git_status = git.git_status_file(parent_ignored, status, self.absolute_path, nil)
end

---@return GitStatus|nil
function FileNode:get_git_status()
  if not self.git_status then
    return nil
  end

  return self.git_status.file and { self.git_status.file }
end

---Create a sanitized partial copy of a node
---@return FileNode cloned
function FileNode:clone()
  local clone = BaseNode.clone(self) --[[@as FileNode]]

  clone.extension = self.extension

  return clone
end

return FileNode
