local git_utils = require("nvim-tree.git.utils")
local icons = require("nvim-tree.renderer.components.icons")
local utils = require("nvim-tree.utils")

local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) DirectoryLinkNode: DirectoryNode
---@field link_to string absolute path
---@field private fs_stat_target uv.fs_stat.result
local DirectoryLinkNode = DirectoryNode:new()

---Static factory method
---@param explorer Explorer
---@param parent DirectoryNode
---@param absolute_path string
---@param link_to string
---@param name string
---@param fs_stat uv.fs_stat.result?
---@param fs_stat_target uv.fs_stat.result
---@return DirectoryLinkNode? nil on vim.loop.fs_realpath failure
function DirectoryLinkNode:create(explorer, parent, absolute_path, link_to, name, fs_stat, fs_stat_target)
  -- create DirectoryNode with the target path for the watcher
  local o = DirectoryNode:create(explorer, parent, link_to, name, fs_stat)

  o = self:new(o)

  -- reset absolute path to the link itself
  o.absolute_path = absolute_path

  o.type = "link"
  o.link_to = link_to
  o.fs_stat_target = fs_stat_target

  return o
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

---Maybe override name
---@return HighlightedString name
function DirectoryLinkNode:highlighted_name()
  local name = DirectoryNode.highlighted_name(self)

  if self.explorer.opts.renderer.symlink_destination then
    local link_to = utils.path_relative(self.link_to, self.explorer.absolute_path)
    name.str = string.format("%s%s%s", name.str, icons.i.symlink_arrow, link_to)
    name.hl = { "NvimTreeSymlinkFolderName" }
  end

  return name
end

---@return HighlightedString name
function DirectoryLinkNode:highlighted_icon()
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
