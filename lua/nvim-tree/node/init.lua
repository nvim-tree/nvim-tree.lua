local git = require("nvim-tree.git")

---@class (exact) BaseNode
---@field private __index? table
---@field type NODE_TYPE
---@field explorer Explorer
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.fs_stat.result|nil
---@field git_status GitStatus|nil
---@field hidden boolean
---@field is_dot boolean
---@field name string|nil
---@field parent DirectoryNode|nil
---@field watcher Watcher|nil
---@field diag_status DiagStatus|nil
local BaseNode = {}

---@alias Node BaseNode|DirectoryNode|FileNode|LinkNode

---@param o BaseNode|nil
---@return BaseNode
function BaseNode:new(o)
  o = o or {}

  setmetatable(o, self)
  self.__index = self

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

---@param parent_ignored boolean
---@param status table|nil
function BaseNode:update_git_status(parent_ignored, status)
  local get_status
  if self.nodes then
    get_status = git.git_status_file
  else
    get_status = git.git_status_file
  end

  -- status of the node's absolute path
  self.git_status = get_status(parent_ignored, status, self.absolute_path)

  -- status of the link target, if the link itself is not dirty
  if self.link_to and not self.git_status then
    self.git_status = get_status(parent_ignored, status, self.link_to)
  end
end

---@return GitStatus|nil
function BaseNode:get_git_status()
  if not self.git_status then
    -- status doesn't exist
    return nil
  end

  if not self.nodes then
    -- file
    return self.git_status.file and { self.git_status.file }
  end

  -- dir
  if not self.explorer.opts.git.show_on_dirs then
    return nil
  end

  local status = {}
  if not require("nvim-tree.lib").get_last_group_node(self).open or self.explorer.opts.git.show_on_open_dirs then
    -- dir is closed or we should show on open_dirs
    if self.git_status.file ~= nil then
      table.insert(status, self.git_status.file)
    end
    if self.git_status.dir ~= nil then
      if self.git_status.dir.direct ~= nil then
        for _, s in pairs(self.git_status.dir.direct) do
          table.insert(status, s)
        end
      end
      if self.git_status.dir.indirect ~= nil then
        for _, s in pairs(self.git_status.dir.indirect) do
          table.insert(status, s)
        end
      end
    end
  else
    -- dir is open and we shouldn't show on open_dirs
    if self.git_status.file ~= nil then
      table.insert(status, self.git_status.file)
    end
    if self.git_status.dir ~= nil and self.git_status.dir.direct ~= nil then
      local deleted = {
        [" D"] = true,
        ["D "] = true,
        ["RD"] = true,
        ["DD"] = true,
      }
      for _, s in pairs(self.git_status.dir.direct) do
        if deleted[s] then
          table.insert(status, s)
        end
      end
    end
  end
  if #status == 0 then
    return nil
  else
    return status
  end
end

---@param projects table
function BaseNode:reload_node_status(projects)
  local toplevel = git.get_toplevel(self.absolute_path)
  local status = projects[toplevel] or {}
  for _, node in ipairs(self.nodes) do
    node:update_git_status(self:is_git_ignored(), status)
    if node.nodes and #node.nodes > 0 then
      self:reload_node_status(projects)
    end
  end
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
