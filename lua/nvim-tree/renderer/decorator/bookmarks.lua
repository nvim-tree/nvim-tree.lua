local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorBookmarks: Decorator
---@field icon HighlightedString?
local DecoratorBookmarks = Decorator:extend()

---@class DecoratorBookmarks
---@overload fun(explorer: DecoratorArgs): DecoratorBookmarks

---@protected
---@param args DecoratorArgs
function DecoratorBookmarks:new(args)
  Decorator.new(self, {
    explorer       = args.explorer,
    enabled        = true,
    hl_pos         = args.explorer.opts.renderer.highlight_bookmarks or "none",
    icon_placement = args.explorer.opts.renderer.icons.bookmarks_placement or "none",
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
