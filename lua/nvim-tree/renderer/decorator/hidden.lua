local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT
local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorHidden: Decorator
---@field icon HighlightedString?
local DecoratorHidden = Decorator:new()

---Static factory method
---@param opts table
---@param explorer Explorer
---@return DecoratorHidden
function DecoratorHidden:create(opts, explorer)
  ---@type DecoratorHidden
  local o = {
    explorer = explorer,
    enabled = true,
    hl_pos = HL_POSITION[opts.renderer.highlight_hidden] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT[opts.renderer.icons.hidden_placement] or ICON_PLACEMENT.none,
  }
  o = self:new(o) --[[@as DecoratorHidden]]

  if opts.renderer.icons.show.hidden then
    o.icon = {
      str = opts.renderer.icons.glyphs.hidden,
      hl = { "NvimTreeHiddenIcon" },
    }
    o:define_sign(o.icon)
  end

  return o
end

---Hidden icon: renderer.icons.show.hidden and node starts with `.` (dotfile).
---@param node Node
---@return HighlightedString[]|nil icons
function DecoratorHidden:calculate_icons(node)
  if self.enabled and node:is_dotfile() then
    return { self.icon }
  end
end

---Hidden highlight: renderer.highlight_hidden and node starts with `.` (dotfile).
---@param node Node
---@return string|nil group
function DecoratorHidden:calculate_highlight(node)
  if not self.enabled or self.hl_pos == HL_POSITION.none or not node:is_dotfile() then
    return nil
  end

  if node.nodes then
    return "NvimTreeHiddenFolderHL"
  else
    return "NvimTreeHiddenFileHL"
  end
end

return DecoratorHidden
