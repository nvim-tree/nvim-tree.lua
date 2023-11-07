local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

--- @class Decorator
--- @field protected enabled boolean
--- @field protected hl_pos HL_POSITION
--- @field protected icon_placement ICON_PLACEMENT
local Decorator = {}

--- @param o Decorator|nil
--- @return Decorator
function Decorator:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  return o
end

--- Maybe highlight groups
--- @param node table
--- @return string|nil icon highlight group
--- @return string|nil name highlight group
function Decorator:groups_icon_name(node)
  local icon_hl, name_hl

  if self.enabled and self.hl_pos ~= HL_POSITION.none then
    local hl = self:get_highlight(node)

    if self.hl_pos == HL_POSITION.all or self.hl_pos == HL_POSITION.icon then
      icon_hl = hl
    end
    if self.hl_pos == HL_POSITION.all or self.hl_pos == HL_POSITION.name then
      name_hl = hl
    end
  end

  return icon_hl, name_hl
end

--- Maybe icon sign
--- @param node table
--- @return string|nil name
function Decorator:sign_name(node)
  if not self.enabled or self.icon_placement ~= ICON_PLACEMENT.signcolumn then
    return
  end

  local icon = self:get_icon(node)
  if icon then
    return icon.hl[1]
  end
end

---@diagnostic disable: unused-local
-- luacheck: push no unused args

--- Maybe icon
--- @param node table
--- @return HighlightedString|nil modified icon
function Decorator:get_icon(node) end

--- Maybe highlight group
--- @protected
--- @param node table
--- @return string|nil group
function Decorator:get_highlight(node) end

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
