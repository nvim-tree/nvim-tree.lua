local Decorator = require("nvim-tree.renderer.decorator")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) DecoratorHidden: Decorator
---@field private explorer Explorer
---@field private icon HighlightedString?
local DecoratorHidden = Decorator:extend()

---@class DecoratorHidden
---@overload fun(explorer: Explorer): DecoratorHidden

---@protected
---@param explorer Explorer
function DecoratorHidden:new(explorer)
  self.explorer = explorer

  ---@type DecoratorArgs
  local args = {
    enabled         = true,
    highlight_range = self.explorer.opts.renderer.highlight_hidden or "none",
    icon_placement  = self.explorer.opts.renderer.icons.hidden_placement or "none",
  }

  DecoratorHidden.super.new(self, args)

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
---@return HighlightedString[]|nil icons
function DecoratorHidden:icons(node)
  if self.enabled and node:is_dotfile() then
    return { self.icon }
  end
end

---Hidden highlight: renderer.highlight_hidden and node starts with `.` (dotfile).
---@param node Node
---@return string|nil group
function DecoratorHidden:highlight_group(node)
  if not self.enabled or self.highlight_range == "none" or not node:is_dotfile() then
    return nil
  end

  if node:is(DirectoryNode) then
    return "NvimTreeHiddenFolderHL"
  else
    return "NvimTreeHiddenFileHL"
  end
end

return DecoratorHidden
