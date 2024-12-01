local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) BookmarkDecorator: Decorator
---@field private explorer Explorer
---@field private icon HighlightedString?
local BookmarkDecorator = Decorator:extend()

---@class BookmarkDecorator
---@overload fun(args: DecoratorArgs): BookmarkDecorator

---@protected
---@param args DecoratorArgs
function BookmarkDecorator:new(args)
  self.explorer        = args.explorer

  self.enabled         = true
  self.highlight_range = self.explorer.opts.renderer.highlight_bookmarks or "none"
  self.icon_placement  = self.explorer.opts.renderer.icons.bookmarks_placement or "none"

  if self.explorer.opts.renderer.icons.show.bookmarks then
    self.icon = {
      str = self.explorer.opts.renderer.icons.glyphs.bookmark,
      hl = { "NvimTreeBookmarkIcon" },
    }
    self:define_sign(self.icon)
  end
end

---Bookmark icon: renderer.icons.show.bookmarks and node is marked
---@param node Node
---@return HighlightedString[]? icons
function BookmarkDecorator:icons(node)
  if self.explorer.marks:get(node) then
    return { self.icon }
  end
end

---Bookmark highlight: renderer.highlight_bookmarks and node is marked
---@param node Node
---@return string? highlight_group
function BookmarkDecorator:highlight_group(node)
  if self.highlight_range ~= "none" and self.explorer.marks:get(node) then
    return "NvimTreeBookmarkHL"
  end
end

return BookmarkDecorator
