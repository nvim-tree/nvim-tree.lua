local git_utils = require("nvim-tree.git.utils")
local icons = require("nvim-tree.renderer.components.devicons")
local notify = require("nvim-tree.notify")
local Iterator = require("nvim-tree.iterators.node-iterator")

local Node = require("nvim-tree.node")

---@class (exact) DirectoryNode: Node
---@field has_children boolean
---@field group_next DirectoryNode? -- If node is grouped, this points to the next child dir/link node
---@field nodes Node[]
---@field open boolean
---@field hidden_stats table? -- Each field of this table is a key for source and value for count
---@field private watcher Watcher?
local DirectoryNode = Node:extend()

---@class DirectoryNode
---@overload fun(args: NodeArgs): DirectoryNode

---@protected
---@param args NodeArgs
function DirectoryNode:new(args)
  DirectoryNode.super.new(self, args)

  local handle       = vim.loop.fs_scandir(args.absolute_path)
  local has_children = handle and vim.loop.fs_scandir_next(handle) ~= nil or false

  self.type          = "directory"

  self.has_children  = has_children
  self.group_next    = nil
  self.nodes         = {}
  self.open          = false
  self.hidden_stats  = nil

  self.watcher       = require("nvim-tree.explorer.watch").create_watcher(self)
end

function DirectoryNode:destroy()
  self:destroy_watcher()

  if self.nodes then
    for _, node in pairs(self.nodes) do
      node:destroy()
    end
  end

  Node.destroy(self)
end

---Halt and remove the watcher for this node
function DirectoryNode:destroy_watcher()
  if self.watcher then
    self.watcher:destroy()
    self.watcher = nil
  end
end

---Update the git_status of the directory
---@param parent_ignored boolean
---@param project nvim_tree.git.Project?
function DirectoryNode:update_git_status(parent_ignored, project)
  self.git_status = git_utils.git_status_dir(parent_ignored, project, self.absolute_path, nil)
end

---@return nvim_tree.git.XY[]?
function DirectoryNode:get_git_xy()
  if not self.git_status or not self.explorer.opts.git.show_on_dirs then
    return nil
  end

  local xys = {}
  if not self:last_group_node().open or self.explorer.opts.git.show_on_open_dirs then
    -- dir is closed or we should show on open_dirs
    if self.git_status.file ~= nil then
      table.insert(xys, self.git_status.file)
    end
    if self.git_status.dir ~= nil then
      if self.git_status.dir.direct ~= nil then
        for _, s in pairs(self.git_status.dir.direct) do
          table.insert(xys, s)
        end
      end
      if self.git_status.dir.indirect ~= nil then
        for _, s in pairs(self.git_status.dir.indirect) do
          table.insert(xys, s)
        end
      end
    end
  else
    -- dir is open and we shouldn't show on open_dirs
    if self.git_status.file ~= nil then
      table.insert(xys, self.git_status.file)
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
          table.insert(xys, s)
        end
      end
    end
  end
  if #xys == 0 then
    return nil
  else
    return xys
  end
end

-- If node is grouped, return the last node in the group. Otherwise, return the given node.
---@return DirectoryNode
function DirectoryNode:last_group_node()
  return self.group_next and self.group_next:last_group_node() or self
end

---Return the one and only one child directory
---@return DirectoryNode?
function DirectoryNode:single_child_directory()
  if #self.nodes == 1 then
    return self.nodes[1]:as(DirectoryNode)
  end
end

---@private
-- Toggle group empty folders
function DirectoryNode:toggle_group_folders()
  local is_grouped = self.group_next ~= nil

  if is_grouped then
    self:ungroup_empty_folders()
  else
    self:group_empty_folders()
  end
end

---Group empty folders
-- Recursively group nodes
---@private
---@return Node[]
function DirectoryNode:group_empty_folders()
  local single_child = self:single_child_directory()
  if self.explorer.opts.renderer.group_empty and self.parent and single_child then
    self.group_next = single_child
    local ns = single_child:group_empty_folders()
    self.nodes = ns or {}
    return ns
  end
  return self.nodes
end

---Ungroup empty folders
-- If a node is grouped, ungroup it: put node.group_next to the node.nodes and set node.group_next to nil
---@private
function DirectoryNode:ungroup_empty_folders()
  if self.group_next then
    self.group_next:ungroup_empty_folders()
    self.nodes = { self.group_next }
    self.group_next = nil
  end
end

---@param toggle_group boolean?
function DirectoryNode:expand_or_collapse(toggle_group)
  toggle_group = toggle_group or false
  if self.has_children then
    self.has_children = false
  end

  if #self.nodes == 0 then
    self.explorer:expand_dir_node(self)
  end

  local head_node = self:get_parent_of_group() or self
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

  local node = head_node
  while node do
    node.open = next_open
    node = node.group_next
  end

  self.explorer.renderer:draw()
end

---@return nvim_tree.api.highlighted_string icon
function DirectoryNode:highlighted_icon()
  if not self.explorer.opts.renderer.icons.show.folder then
    return self:highlighted_icon_empty()
  end

  local str, hl

  -- devicon if enabled and available
  if self.explorer.opts.renderer.icons.web_devicons.folder.enable then
    str, hl = icons.get_icon(self.name)
    if not self.explorer.opts.renderer.icons.web_devicons.folder.color then
      hl = nil
    end
  end

  -- default icon from opts
  if not str then
    if #self.nodes ~= 0 or self.has_children then
      if self.open then
        str = self.explorer.opts.renderer.icons.glyphs.folder.open
      else
        str = self.explorer.opts.renderer.icons.glyphs.folder.default
      end
    else
      if self.open then
        str = self.explorer.opts.renderer.icons.glyphs.folder.empty_open
      else
        str = self.explorer.opts.renderer.icons.glyphs.folder.empty
      end
    end
  end

  -- default hl
  if not hl then
    if self.open then
      hl = "NvimTreeOpenedFolderIcon"
    else
      hl = "NvimTreeClosedFolderIcon"
    end
  end

  return { str = str, hl = { hl } }
end

---@return nvim_tree.api.highlighted_string icon
function DirectoryNode:highlighted_name()
  local str, hl

  local name = self.name
  local next = self.group_next
  while next do
    name = string.format("%s/%s", name, next.name)
    next = next.group_next
  end

  if self.group_next and type(self.explorer.opts.renderer.group_empty) == "function" then
    local new_name = self.explorer.opts.renderer.group_empty(name)
    if type(new_name) == "string" then
      name = new_name
    else
      notify.warn(string.format("Invalid return type for field renderer.group_empty. Expected string, got %s", type(new_name)))
    end
  end
  str = string.format("%s%s", name, self.explorer.opts.renderer.add_trailing and "/" or "")

  hl = "NvimTreeFolderName"
  if vim.tbl_contains(self.explorer.opts.renderer.special_files, self.absolute_path) or vim.tbl_contains(self.explorer.opts.renderer.special_files, self.name) then
    hl = "NvimTreeSpecialFolderName"
  elseif self.open then
    hl = "NvimTreeOpenedFolderName"
  elseif #self.nodes == 0 and not self.has_children then
    hl = "NvimTreeEmptyFolderName"
  end

  return { str = str, hl = { hl } }
end

---Create a sanitized partial copy of a node, populating children recursively.
---@param api_nodes table<number, nvim_tree.api.Node>? optional map of uids to api node to populate
---@return nvim_tree.api.DirectoryNode cloned
function DirectoryNode:clone(api_nodes)
  local clone        = Node.clone(self, api_nodes) --[[@as nvim_tree.api.DirectoryNode]]

  clone.has_children = self.has_children
  clone.nodes        = {}
  clone.open         = self.open

  local clone_child
  for _, child in ipairs(self.nodes) do
    clone_child = child:clone(api_nodes)
    clone_child.parent = clone
    table.insert(clone.nodes, clone_child)
  end

  return clone
end

---@private
---@param should_descend fun(expansion_count: integer, node: Node): boolean
---@return fun(expansion_count: integer, node: Node): boolean
function DirectoryNode:limit_folder_discovery(should_descend)
  local MAX_FOLDER_DISCOVERY = self.explorer.opts.actions.expand_all.max_folder_discovery
  return function(expansion_count, node)
    local should_halt = expansion_count >= MAX_FOLDER_DISCOVERY
    if should_halt then
      notify.warn("expansion iteration was halted after " .. MAX_FOLDER_DISCOVERY .. " discovered folders")
      return false
    end

    return should_descend(expansion_count, node)
  end
end

---@param expansion_count integer
---@param should_descend fun(expansion_count: integer, node: Node): boolean
---@return boolean
function DirectoryNode:should_expand(expansion_count, should_descend)
  if not self.open and should_descend(expansion_count, self) then
    if #self.nodes == 0 then
      self.explorer:expand_dir_node(self) -- populate node.group_next
    end

    if self.group_next then
      local expand_next = self.group_next:should_expand(expansion_count, should_descend)
      if expand_next then
        self.open = true
      end
      return expand_next
    else
      return true
    end
  end
  return false
end

---@param list string[]
---@return table
local function to_lookup_table(list)
  local table = {}
  for _, element in ipairs(list) do
    table[element] = true
  end

  return table
end

---@param _ integer
---@param node Node
---@return boolean
local function descend_until_empty(_, node)
  local EXCLUDE = to_lookup_table(node.explorer.opts.actions.expand_all.exclude)
  local should_exclude = EXCLUDE[node.name]
  return not should_exclude
end

---@param expand_opts? nvim_tree.api.node.expand.Opts
function DirectoryNode:expand(expand_opts)
  local expansion_count = 0

  local should_descend = self:limit_folder_discovery((expand_opts and expand_opts.expand_until) or descend_until_empty)


  if self.parent and self.nodes and not self.open then
    expansion_count = expansion_count + 1
    self:expand_dir_node()
  end

  Iterator.builder(self.nodes)
    :hidden()
    :applier(function(node)
      if node:should_expand(expansion_count, should_descend) then
        expansion_count = expansion_count + 1
        node:expand_dir_node()
      end
    end)
    :recursor(function(node)
      if not should_descend(expansion_count, node) then
        return nil
      end

      if node.group_next then
        return { node.group_next }
      end

      if node.open and node.nodes then
        return node.nodes
      end

      return nil
    end)
    :iterate()

  self.explorer.renderer:draw()
end

function DirectoryNode:expand_dir_node()
  local node = self:last_group_node()
  node.open = true
  if #node.nodes == 0 then
    self.explorer:expand_dir_node(node)
  end
end

return DirectoryNode
