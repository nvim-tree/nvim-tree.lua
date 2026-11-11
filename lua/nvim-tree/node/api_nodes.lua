local api = require("nvim-tree.api")

-- Implementations of nvim_tree.api node classes
-- TODO #3379 type check the node constructor arg

--
-- Node
--
---@class (exact) nvim_tree.api.Node: nvim_tree.Class
---@field private uid_node number
---@overload fun(node: Node): nvim_tree.api.Node
local ApiNode = api.Node

---@param node Node
function ApiNode:new(node)
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
end

---@return number uid_node
function ApiNode:get_uid_node()
  return self.uid_node
end

--
-- DirectoryNode
--
---@class nvim_tree.api.DirectoryNode
---@overload fun(node: DirectoryNode): nvim_tree.api.DirectoryNode
local ApiDirectoryNode = api.DirectoryNode

---@param node DirectoryNode
function ApiDirectoryNode:new(node)
  if not node then
    return
  end

  ApiDirectoryNode.super.new(self, node)

  self.has_children = node.has_children
  self.nodes        = {}
  self.open         = node.open

  local child_node
  for _, child in ipairs(node.nodes) do
    child_node = child:to_api_node()
    child_node.parent = self
    table.insert(self.nodes, child_node)
  end
end

--
-- RootNode
--
---@class nvim_tree.api.RootNode
---@overload fun(node: RootNode): nvim_tree.api.RootNode
local ApiRootNode = api.RootNode

---@param node RootNode
function ApiRootNode:new(node)
  if not node then
    return
  end

  ApiRootNode.super.new(self, node)
end

--
-- FileNode
--
---@class nvim_tree.api.FileNode
---@overload fun(node: FileNode): nvim_tree.api.FileNode
local ApiFileNode = api.FileNode

---@param node FileNode
function ApiFileNode:new(node)
  if not node then
    return
  end

  ApiFileNode.super.new(self, node)

  self.extension = node.extension
end

--
-- LinkNode
--
---@class nvim_tree.api.LinkNode
---@overload fun(node: LinkNode): nvim_tree.api.LinkNode
local ApiLinkNode = api.LinkNode

---@param node LinkNode
function ApiLinkNode:new(node)
  if not node then
    return
  end

  self.link_to = node.link_to
  self.fs_stat_target = node.fs_stat_target
end

--
-- DirectoryLinkNode
--
---@class nvim_tree.api.DirectoryLinkNode
---@overload fun(node: DirectoryLinkNode): nvim_tree.api.DirectoryLinkNode
local ApiDirectoryLinkNode = api.DirectoryLinkNode

---@param node DirectoryLinkNode
function ApiDirectoryLinkNode:new(node)
  if not node then
    return
  end

  ApiLinkNode.new(self, node)

  ApiDirectoryLinkNode.super.new(self, node)
end

--
-- FileLinkNode
--
---@class nvim_tree.api.FileLinkNode
---@overload fun(node: FileLinkNode): nvim_tree.api.FileLinkNode
local ApiFileLinkNode = api.FileLinkNode

---@param node FileLinkNode
function ApiFileLinkNode:new(node)
  ApiLinkNode.new(self, node)
  ApiFileLinkNode.super.new(self, node)
end
