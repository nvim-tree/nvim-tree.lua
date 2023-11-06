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
--- @param _ table node
--- @return HighlightedString|nil modified icon
function Decorator:get_icon(_) end

--- Node highlight group
--- @param _ table node
--- @return string|nil group
function Decorator:get_highlight(_) end

---@diagnostic enable: unused-local

--- Define a sign
--- @protected
--- @param icon HighlightedString|nil
function Decorator:define_sign(icon)
  if icon and #icon.hl > 0 then
    local name = icon.hl[1]

    if not vim.tbl_isempty(vim.fn.sign_getdefined(name)) then
      vim.fn.sign_undefine(name)
    end

    vim.fn.sign_define(name, {
      text = icon.str,
      texthl = icon.hl[1],
    })
  end
end

return Decorator
