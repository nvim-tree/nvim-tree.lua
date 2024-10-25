local buffers = require("nvim-tree.buffers")

local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

local Decorator = require("nvim-tree.renderer.decorator")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) DecoratorModified: Decorator
---@field icon HighlightedString|nil
local DecoratorModified = Decorator:new()

---Static factory method
---@param opts table
---@param explorer Explorer
---@return DecoratorModified
function DecoratorModified:create(opts, explorer)
  ---@type DecoratorModified
  local o = {
    explorer = explorer,
    enabled = opts.modified.enable,
    hl_pos = HL_POSITION[opts.renderer.highlight_modified] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT[opts.renderer.icons.modified_placement] or ICON_PLACEMENT.none,
  }
  o = self:new(o) --[[@as DecoratorModified]]

  if not o.enabled then
    return o
  end

  if opts.renderer.icons.show.modified then
    o.icon = {
      str = opts.renderer.icons.glyphs.modified,
      hl = { "NvimTreeModifiedIcon" },
    }
    o:define_sign(o.icon)
  end

  return o
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
  if not self.enabled or self.hl_pos == HL_POSITION.none or not buffers.is_modified(node) then
    return nil
  end

  if node:is(DirectoryNode) then
    return "NvimTreeModifiedFolderHL"
  else
    return "NvimTreeModifiedFileHL"
  end
end

return DecoratorModified
