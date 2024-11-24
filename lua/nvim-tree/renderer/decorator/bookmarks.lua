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

  ---@type DecoratorArgs
  local args = {
    enabled         = true,
    highlight_range = self.explorer.opts.renderer.highlight_bookmarks or "none",
    icon_placement  = self.explorer.opts.renderer.icons.bookmarks_placement or "none",
  }

  DecoratorBookmarks.super.new(self, args)

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
function DecoratorBookmarks:icons(node)
  if self.explorer.marks:get(node) then
    return { self.icon }
  end
end

---Bookmark highlight: renderer.highlight_bookmarks and node is marked
---@param node Node
---@return string? highlight_group
function DecoratorBookmarks:highlight_group(node)
  if self.highlight_range ~= "none" and self.explorer.marks:get(node) then
    return "NvimTreeBookmarkHL"
  end
end

return DecoratorBookmarks
