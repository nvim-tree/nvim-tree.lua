local copy_paste

local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

local Decorator = require "nvim-tree.renderer.decorator"

---@class DecoratorCopied: Decorator
---@field enabled boolean
---@field icon HighlightedString|nil
local DecoratorCopied = Decorator:new()

---@param opts table
---@return DecoratorCopied
function DecoratorCopied:new(opts)
  local o = Decorator.new(self, {
    enabled = true,
    hl_pos = HL_POSITION[opts.renderer.highlight_clipboard] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT.none,
  })
  ---@cast o DecoratorCopied

  -- cyclic
  copy_paste = copy_paste or require "nvim-tree.actions.fs.copy-paste"

  return o
end

---Copied highlight: renderer.highlight_clipboard and node is copied
---@param node Node
---@return string|nil group
function DecoratorCopied:calculate_highlight(node)
  if self.hl_pos ~= HL_POSITION.none and copy_paste.is_copied(node) then
    return "NvimTreeCopiedHL"
  end
end

return DecoratorCopied
