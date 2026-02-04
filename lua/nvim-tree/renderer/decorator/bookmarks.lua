local BuiltinDecorator = require("nvim-tree.renderer.decorator.builtin")

---@class (exact) BookmarkDecorator: BuiltinDecorator
---@field private icon nvim_tree.api.highlighted_string?
local BookmarkDecorator = BuiltinDecorator:extend()

---@class BookmarkDecorator
---@overload fun(args: BuiltinDecoratorArgs): BookmarkDecorator

---@protected
---@param args BuiltinDecoratorArgs
function BookmarkDecorator:new(args)
  BookmarkDecorator.super.new(self, args)

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
---@return nvim_tree.api.highlighted_string[]? icons
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
