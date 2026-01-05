local git_utils = require("nvim-tree.git.utils")
local utils = require("nvim-tree.utils")

local DirectoryNode = require("nvim-tree.node.directory")
local LinkNode = require("nvim-tree.node.link")

---@class (exact) DirectoryLinkNode: DirectoryNode, LinkNode
local DirectoryLinkNode = DirectoryNode:extend()
DirectoryLinkNode:implement(LinkNode)

---@class DirectoryLinkNode
---@overload fun(args: LinkNodeArgs): DirectoryLinkNode

---@protected
---@param args LinkNodeArgs
function DirectoryLinkNode:new(args)
  LinkNode.new(self, args)

  -- create DirectoryNode with watcher on link_to
  local absolute_path = args.absolute_path
  args.absolute_path = args.link_to
  DirectoryLinkNode.super.new(self, args)

  self.type          = "link"

  -- reset absolute path to the link itself
  self.absolute_path = absolute_path
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
    hl  = "NvimTreeOpenedFolderIcon"
  else
    str = self.explorer.opts.renderer.icons.glyphs.folder.symlink
    hl  = "NvimTreeClosedFolderIcon"
  end

  return { str = str, hl = { hl } }
end

---Maybe override name with arrow
---@return HighlightedString name
function DirectoryLinkNode:highlighted_name()
  local name = DirectoryNode.highlighted_name(self)

  if self.explorer.opts.renderer.symlink_destination then
    local link_to = utils.path_relative(self.link_to, self.explorer.absolute_path)
    if self.explorer.opts.renderer.add_trailing then
      link_to = utils.path_add_trailing(link_to)
    end

    name.str = string.format("%s%s%s", name.str, self.explorer.opts.renderer.icons.symlink_arrow, link_to)
    name.hl  = { "NvimTreeSymlinkFolderName" }
  end

  return name
end

---Create a sanitized partial copy of a node, populating children recursively.
---@param api_nodes table<number, nvim_tree.api.Node>? optional map of uids to api node to populate
---@return nvim_tree.api.DirectoryLinkNode cloned
function DirectoryLinkNode:clone(api_nodes)
  local clone = DirectoryNode.clone(self, api_nodes) --[[@as nvim_tree.api.DirectoryLinkNode]]

  clone.link_to = self.link_to
  clone.fs_stat_target = self.fs_stat_target

  return clone
end

return DirectoryLinkNode
