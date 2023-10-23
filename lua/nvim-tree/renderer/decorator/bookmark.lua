local marks = require "nvim-tree.marks"

local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

local Decorator = require "nvim-tree.renderer.decorator"

--- @class DecoratorBookmark: Decorator
--- @field icon HighlightedString
local DecoratorBookmark = Decorator:new()

--- @param opts table
--- @return DecoratorBookmark
function DecoratorBookmark:new(opts)
  local o = Decorator.new(self, {
    hl_pos = HL_POSITION[opts.renderer.highlight_bookmarks] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT[opts.renderer.icons.bookmarks_placement] or ICON_PLACEMENT.none,
  })
  ---@cast o DecoratorBookmark

  if opts.renderer.icons.show.bookmarks then
    o.icon = {
      str = opts.renderer.icons.glyphs.bookmark,
      hl = { "NvimTreeBookmark" },
    }
    o:define_sign(o.icon)
  end

  return o
end

--- Bookmark  icon: renderer.icons.show.bookmarks and node is marked
function DecoratorBookmark:get_icon(node)
  if marks.get_mark(node) then
    return self.icon
  end
end

--- Bookmark highlight: renderer.highlight_bookmarks and node is marked
function DecoratorBookmark:get_highlight(node)
  if self.hl_pos == HL_POSITION.none then
    return HL_POSITION.none, nil
  end

  local mark = marks.get_mark(node)
  if mark then
    return self.hl_pos, "NvimTreeBookmarkHL"
  else
    return HL_POSITION.none, nil
  end
end

return DecoratorBookmark
