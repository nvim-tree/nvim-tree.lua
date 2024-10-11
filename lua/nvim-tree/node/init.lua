local git = require("nvim-tree.git")

---TODO remove all @cast
---TODO remove all references to directory fields:

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

---@alias Node RootNode|BaseNode|DirectoryNode|FileNode|DirectoryLinkNode|FileLinkNode

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
  --- @cast node BaseNode

  while node.group_next do
    node = node.group_next
  end

  return node
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

-- Toggle group empty folders
function BaseNode:toggle_group_folders()
  local is_grouped = self.group_next ~= nil

  if is_grouped then
    self:ungroup_empty_folders()
  else
    self:group_empty_folders()
  end
end

---Group empty folders
-- Recursively group nodes
---@return Node[]
function BaseNode:group_empty_folders()
  local is_root = not self.parent
  local child_folder_only = self:has_one_child_folder() and self.nodes[1]
  if self.explorer.opts.renderer.group_empty and not is_root and child_folder_only then
    ---@cast self DirectoryNode -- TODO #2886 move this to the class
    self.group_next = child_folder_only
    local ns = child_folder_only:group_empty_folders()
    self.nodes = ns or {}
    return ns
  end
  return self.nodes
end

---Ungroup empty folders
-- If a node is grouped, ungroup it: put node.group_next to the node.nodes and set node.group_next to nil
function BaseNode:ungroup_empty_folders()
  local cur = self
  while cur and cur.group_next do
    cur.nodes = { cur.group_next }
    cur.group_next = nil
    cur = cur.nodes[1]
  end
end

function BaseNode:expand_or_collapse(toggle_group)
  toggle_group = toggle_group or false
  if self.has_children then
    ---@cast self DirectoryNode -- TODO #2886 move this to the class
    self.has_children = false
  end

  if #self.nodes == 0 then
    self.explorer:expand(self)
  end

  local head_node = self:get_parent_of_group()
  if toggle_group then
    head_node:toggle_group_folders()
  end

  local open = self:last_group_node().open
  local next_open
  if toggle_group then
    next_open = open
  else
    next_open = not open
  end
  for _, n in ipairs(head_node:get_all_nodes_in_group()) do
    n.open = next_open
  end

  self.explorer.renderer:draw()
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
