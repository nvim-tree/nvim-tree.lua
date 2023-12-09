local marks = require "nvim-tree.marks"

local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

local Decorator = require "nvim-tree.renderer.decorator"

---@class DecoratorBookmarks: Decorator
---@field icon HighlightedString
local DecoratorBookmarks = Decorator:new()

---@param opts table
---@return DecoratorBookmarks
function DecoratorBookmarks:new(opts)
  local o = Decorator.new(self, {
    enabled = true,
    hl_pos = HL_POSITION[opts.renderer.highlight_bookmarks] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT[opts.renderer.icons.bookmarks_placement] or ICON_PLACEMENT.none,
  })
  ---@cast o DecoratorBookmarks

  if opts.renderer.icons.show.bookmarks then
    o.icon = {
      str = opts.renderer.icons.glyphs.bookmark,
      hl = { "NvimTreeBookmarkIcon" },
    }
    o:define_sign(o.icon)
  end

  return o
end

---Bookmark icon: renderer.icons.show.bookmarks and node is marked
---@param node Node
---@return HighlightedString[]|nil icons
function DecoratorBookmarks:calculate_icons(node)
  if marks.get_mark(node) then
    return { self.icon }
  end
end

---Bookmark highlight: renderer.highlight_bookmarks and node is marked
---@param node Node
---@return string|nil group
function DecoratorBookmarks:calculate_highlight(node)
  if self.hl_pos ~= HL_POSITION.none and marks.get_mark(node) then
    return "NvimTreeBookmarkHL"
  end
end

return DecoratorBookmarks
