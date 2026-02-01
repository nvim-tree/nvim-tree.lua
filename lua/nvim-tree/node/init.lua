local Class = require("nvim-tree.classic")

---Abstract Node class.
---@class (exact) Node: Class
---@field uid_node number vim.loop.hrtime() at construction time
---@field type "file" | "directory" | "link" uv.fs_stat.result.type
---@field explorer Explorer
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.fs_stat.result?
---@field git_status nvim_tree.git.Status?
---@field hidden boolean
---@field name string
---@field parent DirectoryNode?
---@field diag_status DiagStatus?
---@field private is_dot boolean cached is_dotfile
local Node = Class:extend()

---@class (exact) NodeArgs
---@field explorer Explorer
---@field parent DirectoryNode?
---@field absolute_path string
---@field name string
---@field fs_stat uv.fs_stat.result?

---@protected
---@param args NodeArgs
function Node:new(args)
  self.uid_node      = vim.loop.hrtime()
  self.explorer      = args.explorer
  self.absolute_path = args.absolute_path
  self.executable    = false
  self.fs_stat       = args.fs_stat
  self.git_status    = nil
  self.hidden        = false
  self.name          = args.name
  self.parent        = args.parent
  self.diag_status   = nil
  self.is_dot        = false
end

function Node:destroy()
end

---Update the git_status of the node
---Abstract
---@param parent_ignored boolean
---@param project nvim_tree.git.Project?
function Node:update_git_status(parent_ignored, project)
  self:nop(parent_ignored, project)
end

---Short-format statuses
---@return nvim_tree.git.XY[]?
function Node:get_git_xy()
end

---@return boolean
function Node:is_git_ignored()
  return self.git_status ~= nil and self.git_status.file == "!!"
end

---Node or one of its parents begins with a dot
---@return boolean
function Node:is_dotfile()
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

---Get the highest parent of grouped nodes, nil when not grouped
---@return DirectoryNode?
function Node:get_parent_of_group()
  if not self.parent or not self.parent.group_next then
    return nil
  end

  local node = self.parent
  while node do
    if node.parent and node.parent.group_next then
      node = node.parent
    else
      return node
    end
  end
end

---Empty highlighted icon
---@protected
---@return nvim_tree.api.decorator.highlighted_string icon
function Node:highlighted_icon_empty()
  return { str = "", hl = {} }
end

---Highlighted icon for the node
---Empty for base Node
---@return nvim_tree.api.decorator.highlighted_string icon
function Node:highlighted_icon()
  return self:highlighted_icon_empty()
end

---Empty highlighted name
---@protected
---@return nvim_tree.api.decorator.highlighted_string name
function Node:highlighted_name_empty()
  return { str = "", hl = {} }
end

---Highlighted name for the node
---Empty for base Node
---@return nvim_tree.api.decorator.highlighted_string name
function Node:highlighted_name()
  return self:highlighted_name_empty()
end

---Create a sanitized partial copy of a node, populating children recursively.
---@param api_nodes table<number, nvim_tree.api.Node>? optional map of uids to api node to populate
---@return nvim_tree.api.Node cloned
function Node:clone(api_nodes)
  ---@type nvim_tree.api.Node
  local clone = {
    uid_node      = self.uid_node,
    type          = self.type,
    absolute_path = self.absolute_path,
    executable    = self.executable,
    fs_stat       = self.fs_stat,
    git_status    = self.git_status,
    hidden        = self.hidden,
    name          = self.name,
    parent        = nil,
    diag_severity = self.diag_status and self.diag_status.value or nil,
  }

  if api_nodes then
    api_nodes[self.uid_node] = clone
  end

  return clone
end

---@param expansion_count integer
---@param should_descend fun(expansion_count: integer, node: Node): boolean
---@return boolean
function Node:should_expand(expansion_count, should_descend)
  self:nop(expansion_count, should_descend)
  return false
end

---@param expand_opts? nvim_tree.api.node.expand.Opts
function Node:expand(expand_opts)
  if self.parent then
    self.parent:expand(expand_opts)
  end
end

return Node
