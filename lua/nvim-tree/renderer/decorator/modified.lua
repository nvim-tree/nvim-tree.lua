local buffers = require("nvim-tree.buffers")

local Decorator = require("nvim-tree.renderer.decorator")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) ModifiedDecorator: Decorator
---@field private explorer Explorer
---@field private icon nvim_tree.api.decorator.highlighted_string?
local ModifiedDecorator = Decorator:extend()

---@class ModifiedDecorator
---@overload fun(args: DecoratorArgs): ModifiedDecorator

---@protected
---@param args DecoratorArgs
function ModifiedDecorator:new(args)
  self.explorer        = args.explorer

  self.enabled         = true
  self.highlight_range = self.explorer.opts.renderer.highlight_modified or "none"
  self.icon_placement  = self.explorer.opts.renderer.icons.modified_placement or "none"

  if self.explorer.opts.renderer.icons.show.modified then
    self.icon = {
      str = self.explorer.opts.renderer.icons.glyphs.modified,
      hl = { "NvimTreeModifiedIcon" },
    }
    self:define_sign(self.icon)
  end
end

---Modified icon: modified.enable, renderer.icons.show.modified and node is modified
---@param node Node
---@return nvim_tree.api.decorator.highlighted_string[]? icons
function ModifiedDecorator:icons(node)
  if buffers.is_modified(node) then
    return { self.icon }
  end
end

---Modified highlight: modified.enable, renderer.highlight_modified and node is modified
---@param node Node
---@return string? highlight_group
function ModifiedDecorator:highlight_group(node)
  if self.highlight_range == "none" or not buffers.is_modified(node) then
    return nil
  end

  if node:is(DirectoryNode) then
    return "NvimTreeModifiedFolderHL"
  else
    return "NvimTreeModifiedFileHL"
  end
end

return ModifiedDecorator
