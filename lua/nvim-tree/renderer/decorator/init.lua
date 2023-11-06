local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

--- @class Decorator
--- @field enabled boolean
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

--- Icon and name highlight
--- @param node table
--- @param icon_hl string[] icon HL to append to
--- @param name_hl string[] name HL to append to
function Decorator:apply_highlight(node, icon_hl, name_hl)
  if not self.enabled or self.hl_pos == HL_POSITION.none then
    return
  end

  local hl = self:get_highlight(node)

  if self.hl_pos == HL_POSITION.all or self.hl_pos == HL_POSITION.icon then
    table.insert(icon_hl, hl)
  end
  if self.hl_pos == HL_POSITION.all or self.hl_pos == HL_POSITION.name then
    table.insert(name_hl, hl)
  end
end

--- Get the icon as a sign if appropriate
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

--- Node icon
--- @param node table
--- @return HighlightedString|nil modified icon
function Decorator:get_icon(node) end

--- Node highlight group
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
