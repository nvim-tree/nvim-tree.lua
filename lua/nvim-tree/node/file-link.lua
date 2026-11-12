local api = require("nvim-tree.api")
local git_utils = require("nvim-tree.git.utils")
local utils = require("nvim-tree.utils")

local FileNode = require("nvim-tree.node.file")
local LinkNode = require("nvim-tree.node.link")

---@class (exact) FileLinkNode: FileNode, LinkNode
local FileLinkNode = FileNode:extend()
FileLinkNode:implement(LinkNode)

---@class FileLinkNode
---@overload fun(args: LinkNodeArgs): FileLinkNode

---@protected
---@param args LinkNodeArgs
function FileLinkNode:new(args)
  LinkNode.new(self, args)
  FileLinkNode.super.new(self, args)

  self.api_node_class = api.FileLinkNode
  self.type           = "link"
end

---api node constructor
---@param api_node_uid_map? ApiNodeUidMap
---@param node FileLinkNode
function api.FileLinkNode:new(node, api_node_uid_map)
  if not node then
    return
  end

  api.LinkNode.new(self, node)

  api.FileLinkNode.super.new(self, node, api_node_uid_map)
end

function FileLinkNode:destroy()
  FileNode.destroy(self)
end

---Update the git_status of the target otherwise the link itself
---@param parent_ignored boolean
---@param project nvim_tree.git.Project?
function FileLinkNode:update_git_status(parent_ignored, project)
  self.git_status = git_utils.git_status_file(parent_ignored, project, self.link_to, self.absolute_path)
end

---@return nvim_tree.api.highlighted_string icon
function FileLinkNode:highlighted_icon()
  if not self.explorer.opts.renderer.icons.show.file then
    return self:highlighted_icon_empty()
  end

  local str, hl

  -- default icon from opts
  str = self.explorer.opts.renderer.icons.glyphs.symlink
  hl = "NvimTreeSymlinkIcon"

  return { str = str, hl = { hl } }
end

---@return nvim_tree.api.highlighted_string name
function FileLinkNode:highlighted_name()
  local str = self.name
  if self.explorer.opts.renderer.symlink_destination then
    local link_to = utils.path_relative(self.link_to, self.explorer.absolute_path)
    str = string.format("%s%s%s", str, self.explorer.opts.renderer.icons.symlink_arrow, link_to)
  end

  return { str = str, hl = { "NvimTreeSymlink" } }
end

return FileLinkNode
