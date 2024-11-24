local buffers = require("nvim-tree.buffers")

local Decorator = require("nvim-tree.renderer.decorator")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) DecoratorModified: Decorator
---@field private explorer Explorer
---@field private icon HighlightedString?
local DecoratorModified = Decorator:extend()
DecoratorModified.name = "Modified"

---@class DecoratorModified
---@overload fun(args: DecoratorArgs): DecoratorModified

---@protected
---@param args DecoratorArgs
function DecoratorModified:new(args)
  self.explorer = args.explorer

  ---@type AbstractDecoratorArgs
  local a = {
    enabled         = true,
    highlight_range = self.explorer.opts.renderer.highlight_modified or "none",
    icon_placement  = self.explorer.opts.renderer.icons.modified_placement or "none",
  }

  DecoratorModified.super.new(self, a)

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
---@return HighlightedString[]? icons
function DecoratorModified:icons(node)
  if self.enabled and buffers.is_modified(node) then
    return { self.icon }
  end
end

---Modified highlight: modified.enable, renderer.highlight_modified and node is modified
---@param node Node
---@return string? highlight_group
function DecoratorModified:highlight_group(node)
  if not self.enabled or self.highlight_range == "none" or not buffers.is_modified(node) then
    return nil
  end

  if node:is(DirectoryNode) then
    return "NvimTreeModifiedFolderHL"
  else
    return "NvimTreeModifiedFileHL"
  end
end

return DecoratorModified
