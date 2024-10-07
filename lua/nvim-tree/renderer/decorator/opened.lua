local buffers = require("nvim-tree.buffers")

local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

local Decorator = require("nvim-tree.renderer.decorator")

---@class (exact) DecoratorOpened: Decorator
---@field icon HighlightedString|nil
local DecoratorOpened = Decorator:new()

---Static factory method
---@param opts table
---@param explorer Explorer
---@return DecoratorOpened
function DecoratorOpened:create(opts, explorer)
  ---@type DecoratorOpened
  local o = {
    explorer = explorer,
    enabled = true,
    hl_pos = HL_POSITION[opts.renderer.highlight_opened_files] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT.none,
  }
  o = self:new(o) --[[@as DecoratorOpened]]

  return o
end

---Opened highlight: renderer.highlight_opened_files and node has an open buffer
---@param node Node
---@return string|nil group
function DecoratorOpened:calculate_highlight(node)
  if self.hl_pos ~= HL_POSITION.none and buffers.is_opened(node) then
    return "NvimTreeOpenedHL"
  end
end

return DecoratorOpened
