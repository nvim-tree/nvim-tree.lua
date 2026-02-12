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

  self.type = "link"
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

---@return HighlightedString icon
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

---@return HighlightedString name
function FileLinkNode:highlighted_name()
  local str = self.name
  if self.explorer.opts.renderer.symlink_destination then
    local link_to = utils.path_relative(self.link_to, self.explorer.absolute_path)
    str = string.format("%s%s%s", str, self.explorer.opts.renderer.icons.symlink_arrow, link_to)
  end

  return { str = str, hl = { "NvimTreeSymlink" } }
end

---Create a sanitized partial copy of a node
---@param api_nodes table<number, nvim_tree.api.Node>? optional map of uids to api node to populate
---@return nvim_tree.api.FileLinkNode cloned
function FileLinkNode:clone(api_nodes)
  local clone = FileNode.clone(self, api_nodes) --[[@as nvim_tree.api.FileLinkNode]]

  clone.link_to = self.link_to
  clone.fs_stat_target = self.fs_stat_target

  return clone
end

return FileLinkNode
