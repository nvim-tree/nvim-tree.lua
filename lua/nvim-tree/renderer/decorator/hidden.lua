local Decorator = require("nvim-tree.renderer.decorator")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) DecoratorHidden: Decorator
---@field private explorer Explorer
---@field private icon HighlightedString?
local DecoratorHidden = Decorator:extend()

---@class DecoratorHidden
---@overload fun(args: DecoratorArgs): DecoratorHidden

---@protected
---@param args DecoratorArgs
function DecoratorHidden:new(args)
  self.explorer        = args.explorer

  self.enabled         = true
  self.highlight_range = self.explorer.opts.renderer.highlight_hidden or "none"
  self.icon_placement  = self.explorer.opts.renderer.icons.hidden_placement or "none"

  if self.explorer.opts.renderer.icons.show.hidden then
    self.icon = {
      str = self.explorer.opts.renderer.icons.glyphs.hidden,
      hl = { "NvimTreeHiddenIcon" },
    }
    self:define_sign(self.icon)
  end
end

---Hidden icon: renderer.icons.show.hidden and node starts with `.` (dotfile).
---@param node Node
---@return HighlightedString[]? icons
function DecoratorHidden:icons(node)
  if node:is_dotfile() then
    return { self.icon }
  end
end

---Hidden highlight: renderer.highlight_hidden and node starts with `.` (dotfile).
---@param node Node
---@return string? highlight_group
function DecoratorHidden:highlight_group(node)
  if self.highlight_range == "none" or not node:is_dotfile() then
    return nil
  end

  if node:is(DirectoryNode) then
    return "NvimTreeHiddenFolderHL"
  else
    return "NvimTreeHiddenFileHL"
  end
end

return DecoratorHidden
