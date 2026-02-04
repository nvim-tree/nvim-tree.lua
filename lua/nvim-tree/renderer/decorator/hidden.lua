local BuiltinDecorator = require("nvim-tree.renderer.decorator.builtin")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) HiddenDecorator: BuiltinDecorator
---@field private icon nvim_tree.api.highlighted_string?
local HiddenDecorator = BuiltinDecorator:extend()

---@class HiddenDecorator
---@overload fun(args: BuiltinDecoratorArgs): HiddenDecorator

---@protected
---@param args BuiltinDecoratorArgs
function HiddenDecorator:new(args)
  HiddenDecorator.super.new(self, args)

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
---@return nvim_tree.api.highlighted_string[]? icons
function HiddenDecorator:icons(node)
  if node:is_dotfile() then
    return { self.icon }
  end
end

---Hidden highlight: renderer.highlight_hidden and node starts with `.` (dotfile).
---@param node Node
---@return string? highlight_group
function HiddenDecorator:highlight_group(node)
  if self.highlight_range == "none" or not node:is_dotfile() then
    return nil
  end

  if node:is(DirectoryNode) then
    return "NvimTreeHiddenFolderHL"
  else
    return "NvimTreeHiddenFileHL"
  end
end

return HiddenDecorator
