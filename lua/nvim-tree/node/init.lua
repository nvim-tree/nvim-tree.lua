local api = require("nvim-tree.api")
local Class = require("nvim-tree.classic")

---@alias ApiNodeUidMap table<number, nvim_tree.api.Node> map of uids to api node to populate, for caching

---Abstract Node class.
---@class (exact) Node: nvim_tree.Class
---@field uid_node number vim.uv.hrtime() at construction time
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
---@field protected api_node_class nvim_tree.api.Node corresponding api node class
---@field private is_dot boolean cached is_dotfile
local Node = Class:extend()

---@class (exact) NodeArgs
---@field explorer Explorer
---@field parent DirectoryNode?
---@field absolute_path string
---@field name string
---@field fs_stat uv.fs_stat.result?

---@class Node
---@overload fun(args: NodeArgs): Node

---@protected
---@param args NodeArgs
function Node:new(args)
  self.api_node_class = api.Node
  self.uid_node       = vim.uv.hrtime()
  self.explorer       = args.explorer
  self.absolute_path  = args.absolute_path
  self.executable     = false
  self.fs_stat        = args.fs_stat
  self.git_status     = nil
  self.hidden         = false
  self.name           = args.name
  self.parent         = args.parent
  self.diag_status    = nil
  self.is_dot         = false
end

---api node constructor
---@param api_node_uid_map? ApiNodeUidMap
---@param node Node
function api.Node:new(node, api_node_uid_map)
  if not node then
    return
  end

  self.uid_node      = node.uid_node
  self.type          = node.type
  self.absolute_path = node.absolute_path
  self.executable    = node.executable
  self.fs_stat       = node.fs_stat
  self.git_status    = node.git_status
  self.hidden        = node.hidden
  self.name          = node.name
  self.parent        = nil
  self.diag_severity = node.diag_status and node.diag_status.value or nil

  if api_node_uid_map then
    api_node_uid_map[self.uid_node] = self
  end
end

---(Recursively) instantiate an api node
---@param api_node_uid_map? ApiNodeUidMap
---@return nvim_tree.api.Node
function Node:to_api_node(api_node_uid_map)
  return self:api_node_class(api_node_uid_map)
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
---@return nvim_tree.api.highlighted_string icon
function Node:highlighted_icon_empty()
  return { str = "", hl = {} }
end

---Highlighted icon for the node
---Empty for base Node
---@return nvim_tree.api.highlighted_string icon
function Node:highlighted_icon()
  return self:highlighted_icon_empty()
end

---Empty highlighted name
---@protected
---@return nvim_tree.api.highlighted_string name
function Node:highlighted_name_empty()
  return { str = "", hl = {} }
end

---Highlighted name for the node
---Empty for base Node
---@return nvim_tree.api.highlighted_string name
function Node:highlighted_name()
  return self:highlighted_name_empty()
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
