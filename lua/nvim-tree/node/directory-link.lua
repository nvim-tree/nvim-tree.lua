local git_utils = require("nvim-tree.git.utils")
local utils = require("nvim-tree.utils")

local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) DirectoryLinkNode: DirectoryNode, LinkNode
local DirectoryLinkNode = DirectoryNode:extend()

---@param explorer Explorer
---@param parent DirectoryNode
---@param absolute_path string
---@param link_to string
---@param name string
---@param fs_stat uv.fs_stat.result?
---@param fs_stat_target uv.fs_stat.result
function DirectoryLinkNode:new(explorer, parent, absolute_path, link_to, name, fs_stat, fs_stat_target)
  -- create DirectoryNode with the target path for the watcher
  DirectoryLinkNode.super.new(self, explorer, parent, link_to, name, fs_stat)

  -- reset absolute path to the link itself
  self.absolute_path = absolute_path

  self.type = "link"
  self.link_to = link_to
  self.fs_stat_target = fs_stat_target
end

function DirectoryLinkNode:destroy()
  DirectoryNode.destroy(self)
end

---Update the directory git_status of link target and the file status of the link itself
---@param parent_ignored boolean
---@param project GitProject?
function DirectoryLinkNode:update_git_status(parent_ignored, project)
  self.git_status = git_utils.git_status_dir(parent_ignored, project, self.link_to, self.absolute_path)
end

---@return HighlightedString name
function DirectoryLinkNode:highlighted_icon()
  if not self.explorer.opts.renderer.icons.show.folder then
    return self:highlighted_icon_empty()
  end

  local str, hl

  if self.open then
    str = self.explorer.opts.renderer.icons.glyphs.folder.symlink_open
    hl = "NvimTreeOpenedFolderIcon"
  else
    str = self.explorer.opts.renderer.icons.glyphs.folder.symlink
    hl = "NvimTreeClosedFolderIcon"
  end

  return { str = str, hl = { hl } }
end

---Maybe override name with arrow
---@return HighlightedString name
function DirectoryLinkNode:highlighted_name()
  local name = DirectoryNode.highlighted_name(self)

  if self.explorer.opts.renderer.symlink_destination then
    local link_to = utils.path_relative(self.link_to, self.explorer.absolute_path)
    name.str = string.format("%s%s%s", name.str, self.explorer.opts.renderer.icons.symlink_arrow, link_to)
    name.hl = { "NvimTreeSymlinkFolderName" }
  end

  return name
end

---Create a sanitized partial copy of a node, populating children recursively.
---@return DirectoryLinkNode cloned
function DirectoryLinkNode:clone()
  local clone = DirectoryNode.clone(self) --[[@as DirectoryLinkNode]]

  clone.type = self.type
  clone.link_to = self.link_to
  clone.fs_stat_target = self.fs_stat_target

  return clone
end

return DirectoryLinkNode
