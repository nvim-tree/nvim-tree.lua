local git = require("nvim-tree.git")

---Abstract Node class.
---Uses the abstract factory pattern to instantiate child instances.
---@class (exact) BaseNode
---@field private __index? table
---@field type NODE_TYPE
---@field explorer Explorer
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.fs_stat.result?
---@field git_status GitStatus?
---@field hidden boolean
---@field is_dot boolean
---@field name string
---@field parent Node?
---@field watcher Watcher?
---@field diag_status DiagStatus?
local BaseNode = {}

---@alias Node RootNode|BaseNode|DirectoryNode|FileNode|LinkNode

---@param o BaseNode?
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

---From plenary
---Checks if the object is an instance
---This will start with the lowest class and loop over all the superclasses.
---@param self BaseNode
---@param T BaseNode
---@return boolean
function BaseNode:is(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
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
    get_status = git.git_status_dir
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
  if not self:last_group_node().open or self.explorer.opts.git.show_on_open_dirs then
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

-- If node is grouped, return the last node in the group. Otherwise, return the given node.
---@return Node
function BaseNode:last_group_node()
  local node = self

  while node.group_next do
    node = node.group_next
  end

  return node
end

---@param project table|nil
---@param root string|nil
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

---Refresh contents and git status for a single node
function BaseNode:refresh()
  local parent_node = self:get_parent_of_group()
  local toplevel = git.get_toplevel(self.absolute_path)

  git.reload_project(toplevel, self.absolute_path, function()
    local project = git.get_project(toplevel) or {}

    self.explorer:reload(parent_node, project)

    parent_node:update_parent_statuses(project, toplevel)

    self.explorer.renderer:draw()
  end)
end

---Get the highest parent of grouped nodes
---@return Node node or parent
function BaseNode:get_parent_of_group()
  local node = self
  while node and node.parent and node.parent.group_next do
    node = node.parent or node
  end
  return node
end

---@return Node[]
function BaseNode:get_all_nodes_in_group()
  local next_node = self:get_parent_of_group()
  local nodes = {}
  while next_node do
    table.insert(nodes, next_node)
    next_node = next_node.group_next
  end
  return nodes
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
