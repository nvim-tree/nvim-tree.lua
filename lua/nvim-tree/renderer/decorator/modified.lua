local buffers = require("nvim-tree.buffers")

local Decorator = require("nvim-tree.renderer.decorator")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) DecoratorModified: Decorator
---@field private explorer Explorer
---@field private icon HighlightedString?
local DecoratorModified = Decorator:extend()

---@class DecoratorModified
---@overload fun(explorer: Explorer): DecoratorModified

---@protected
---@param explorer Explorer
function DecoratorModified:new(explorer)
  self.explorer = explorer

  DecoratorModified.super.new(self, {
    enabled        = true,
    hl_pos         = self.explorer.opts.renderer.highlight_modified or "none",
    icon_placement = self.explorer.opts.renderer.icons.modified_placement or "none",
  })

  if not self.enabled then
    return
  end

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
---@return HighlightedString[]|nil icons
function DecoratorModified:calculate_icons(node)
  if self.enabled and buffers.is_modified(node) then
    return { self.icon }
  end
end

---Modified highlight: modified.enable, renderer.highlight_modified and node is modified
---@param node Node
---@return string|nil group
function DecoratorModified:calculate_highlight(node)
  if not self.enabled or self.range == "none" or not buffers.is_modified(node) then
    return nil
  end

  if node:is(DirectoryNode) then
    return "NvimTreeModifiedFolderHL"
  else
    return "NvimTreeModifiedFileHL"
  end
end

return DecoratorModified
