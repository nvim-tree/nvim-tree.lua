local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

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
-- luacheck: push no unused args

--- Node icon
--- @param node table
--- @return HighlightedString|nil modified icon
function Decorator:get_icon(node) end

--- Node highlight group
--- @param node table
--- @return string|nil group
function Decorator:get_highlight(node) end

--- Get the icon as a sign if appropriate
--- @param node table
--- @return string|nil name
function Decorator:sign_name(node)
  if self.icon_placement ~= ICON_PLACEMENT.signcolumn then
    return
  end

  local icon = self:get_icon(node)
  if icon then
    return icon.hl[1]
  end
end

---@diagnostic enable: unused-local
-- luacheck: pop

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
