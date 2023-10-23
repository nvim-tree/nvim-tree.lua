--- @class Decorator
--- @field hl_pos HL_POSITION
--- @field icon_placement ICON_PLACEMENT
local Decorator = {}

--- @param o Decorator|nil
--- @return Decorator
function Decorator:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  return o
end

---@diagnostic disable: unused-local

--- Node icon
--- @param node table
--- @return HighlightedString|nil modified icon
function Decorator:get_icon(node) end

--- Node highlight
--- @param node table
--- @return HL_POSITION|nil position
--- @return string|nil group
function Decorator:get_highlight(node) end

---@diagnostic enable: unused-local

--- Define a sign
--- @param icon HighlightedString|nil
function Decorator:define_sign(icon)
  if icon and #icon.hl > 0 then
    vim.fn.sign_define(icon.hl[1], {
      text = icon.str,
      texthl = icon.hl[1],
    })
  end
end

return Decorator
