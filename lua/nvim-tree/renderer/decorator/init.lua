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
    local hl = self:calculate_highlight(node)

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

  local icons = self:calculate_icons(node)
  if icons and #icons > 0 then
    return icons[1].hl[1]
  end
end

--- Icons when ICON_PLACEMENT.before
--- @param node table
--- @return HighlightedString[]|nil icons
function Decorator:icons_before(node)
  if not self.enabled or self.icon_placement ~= ICON_PLACEMENT.before then
    return
  end

  return self:calculate_icons(node)
end

--- Icons when ICON_PLACEMENT.after
--- @param node table
--- @return HighlightedString[]|nil icons
function Decorator:icons_after(node)
  if not self.enabled or self.icon_placement ~= ICON_PLACEMENT.after then
    return
  end

  return self:calculate_icons(node)
end

---@diagnostic disable: unused-local
-- luacheck: push no unused args

--- Maybe icons - abstract
--- @protected
--- @param node table
--- @return HighlightedString[]|nil icons
function Decorator:calculate_icons(node) end

--- Maybe highlight group - abstract
--- @protected
--- @param node table
--- @return string|nil group
function Decorator:calculate_highlight(node) end

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

    if self.icon_placement ~= ICON_PLACEMENT.signcolumn or #icon.str < 1 then
      return
    end

    vim.fn.sign_define(name, {
      text = string.sub(icon.str, 1, 1),
      texthl = icon.hl[1],
    })
  end
end

return Decorator
