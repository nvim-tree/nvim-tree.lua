local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorBookmarks: Decorator
---@field private explorer Explorer
---@field private icon HighlightedString?
local DecoratorBookmarks = Decorator:extend()

---@class DecoratorBookmarks
---@overload fun(explorer: Explorer): DecoratorBookmarks

---@protected
---@param explorer Explorer
function DecoratorBookmarks:new(explorer)
  self.explorer = explorer

  DecoratorBookmarks.super.new(self, {
    enabled        = true,
    hl_pos         = self.explorer.opts.renderer.highlight_bookmarks or "none",
    icon_placement = self.explorer.opts.renderer.icons.bookmarks_placement or "none",
  })

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
---@return HighlightedString[]|nil icons
function DecoratorBookmarks:calculate_icons(node)
  if self.explorer.marks:get(node) then
    return { self.icon }
  end
end

---Bookmark highlight: renderer.highlight_bookmarks and node is marked
---@param node Node
---@return string|nil group
function DecoratorBookmarks:calculate_highlight(node)
  if self.range ~= "none" and self.explorer.marks:get(node) then
    return "NvimTreeBookmarkHL"
  end
end

return DecoratorBookmarks
