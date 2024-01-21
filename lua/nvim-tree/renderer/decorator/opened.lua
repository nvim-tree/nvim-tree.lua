local buffers = require "nvim-tree.buffers"

local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

local Decorator = require "nvim-tree.renderer.decorator"

---@class DecoratorOpened: Decorator
---@field enabled boolean
---@field icon HighlightedString|nil
local DecoratorOpened = Decorator:new()

---@param opts table
---@return DecoratorOpened
function DecoratorOpened:new(opts)
  local o = Decorator.new(self, {
    enabled = true,
    hl_pos = HL_POSITION[opts.renderer.highlight_opened_files] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT.none,
  })
  ---@cast o DecoratorOpened

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
