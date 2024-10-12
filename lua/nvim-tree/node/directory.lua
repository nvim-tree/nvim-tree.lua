local git = require("nvim-tree.git")
local watch = require("nvim-tree.explorer.watch")

local BaseNode = require("nvim-tree.node")

---@class (exact) DirectoryNode: BaseNode
---@field has_children boolean
---@field group_next Node? -- If node is grouped, this points to the next child dir/link node
---@field nodes Node[]
---@field open boolean
---@field hidden_stats table? -- Each field of this table is a key for source and value for count
local DirectoryNode = BaseNode:new()

---Static factory method
---@param explorer Explorer
---@param parent Node?
---@param absolute_path string
---@param name string
---@param fs_stat uv.fs_stat.result|nil
---@return DirectoryNode
function DirectoryNode:create(explorer, parent, absolute_path, name, fs_stat)
  local handle = vim.loop.fs_scandir(absolute_path)
  local has_children = handle and vim.loop.fs_scandir_next(handle) ~= nil or false

  ---@type DirectoryNode
  local o = {
    type = "directory",
    explorer = explorer,
    absolute_path = absolute_path,
    executable = false,
    fs_stat = fs_stat,
    git_status = nil,
    hidden = false,
    is_dot = false,
    name = name,
    parent = parent,
    watcher = nil,
    diag_status = nil,

    has_children = has_children,
    group_next = nil,
    nodes = {},
    open = false,
    hidden_stats = nil,
  }
  o = self:new(o) --[[@as DirectoryNode]]

  o.watcher = watch.create_watcher(o)

  return o
end

function DirectoryNode:destroy()
  BaseNode.destroy(self)
  if self.nodes then
    for _, node in pairs(self.nodes) do
      node:destroy()
    end
  end
end

---Update the GitStatus of the directory
---@param parent_ignored boolean
---@param status table|nil
function DirectoryNode:update_git_status(parent_ignored, status)
  self.git_status = git.git_status_dir(parent_ignored, status, self.absolute_path, nil)
end

---@return GitStatus|nil
function DirectoryNode:get_git_status()
  if not self.git_status or not self.explorer.opts.git.show_on_dirs then
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

function DirectoryNode:expand_or_collapse(toggle_group)
  toggle_group = toggle_group or false
  if self.has_children then
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
---@return DirectoryNode cloned
function DirectoryNode:clone()
  local clone = BaseNode.clone(self) --[[@as DirectoryNode]]

  clone.has_children = self.has_children
  clone.group_next = nil
  clone.nodes = {}
  clone.open = self.open
  clone.hidden_stats = nil

  for _, child in ipairs(self.nodes) do
    table.insert(clone.nodes, child:clone())
  end

  return clone
end

return DirectoryNode
