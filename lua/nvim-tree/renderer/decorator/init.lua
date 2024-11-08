local Class = require("nvim-tree.classic")

---@alias DecoratorRange "none" | "icon" | "name" | "all"
---@alias DecoratorIconPlacement "none" | "before" | "after" | "signcolumn" | "right_align"

---Abstract Decorator
---Uses the factory pattern to instantiate child instances.
---@class (exact) Decorator: Class
---@field protected explorer Explorer
---@field protected enabled boolean
---@field protected range DecoratorRange
---@field protected icon_placement DecoratorIconPlacement
local Decorator = Class:extend()

---@class (exact) DecoratorArgs
---@field explorer Explorer

---@class (exact) AbstractDecoratorArgs: DecoratorArgs
---@field enabled boolean
---@field hl_pos DecoratorRange
---@field icon_placement DecoratorIconPlacement

---@protected
---@param args AbstractDecoratorArgs
function Decorator:new(args)
  self.explorer       = args.explorer
  self.enabled        = args.enabled
  self.range          = args.hl_pos
  self.icon_placement = args.icon_placement
end

---Maybe highlight groups
---@param node Node
---@return string|nil icon highlight group
---@return string|nil name highlight group
function Decorator:groups_icon_name(node)
  local icon_hl, name_hl

  if self.enabled and self.range ~= "none" then
    local hl = self:calculate_highlight(node)

    if self.range == "all" or self.range == "icon" then
      icon_hl = hl
    end
    if self.range == "all" or self.range == "name" then
      name_hl = hl
    end
  end

  return icon_hl, name_hl
end

---Maybe icon sign
---@param node Node
---@return string|nil name
function Decorator:sign_name(node)
  if not self.enabled or self.icon_placement ~= "signcolumn" then
    return
  end

  local icons = self:calculate_icons(node)
  if icons and #icons > 0 then
    return icons[1].hl[1]
  end
end

---Icons when "before"
---@param node Node
---@return HighlightedString[]|nil icons
function Decorator:icons_before(node)
  if not self.enabled or self.icon_placement ~= "before" then
    return
  end

  return self:calculate_icons(node)
end

---Icons when "after"
---@param node Node
---@return HighlightedString[]|nil icons
function Decorator:icons_after(node)
  if not self.enabled or self.icon_placement ~= "after" then
    return
  end

  return self:calculate_icons(node)
end

---Icons when "right_align"
---@param node Node
---@return HighlightedString[]|nil icons
function Decorator:icons_right_align(node)
  if not self.enabled or self.icon_placement ~= "right_align" then
    return
  end

  return self:calculate_icons(node)
end

---Maybe icons, optionally implemented
---@protected
---@param _ Node
---@return HighlightedString[]|nil icons
function Decorator:calculate_icons(_)
  return nil
end

---Maybe highlight group, optionally implemented
---@protected
---@param _ Node
---@return string|nil group
function Decorator:calculate_highlight(_)
  return nil
end

---Define a sign
---@protected
---@param icon HighlightedString|nil
function Decorator:define_sign(icon)
  if icon and #icon.hl > 0 then
    local name = icon.hl[1]

    if not vim.tbl_isempty(vim.fn.sign_getdefined(name)) then
      vim.fn.sign_undefine(name)
    end

    -- don't use sign if not defined
    if #icon.str < 1 then
      self.icon_placement = "none"
      return
    end

    -- byte index of the next character, allowing for wide
    local bi = vim.fn.byteidx(icon.str, 1)

    -- first (wide) character, falls back to empty string
    local text = string.sub(icon.str, 1, bi)
    vim.fn.sign_define(name, {
      text = text,
      texthl = name,
    })
  end
end

return Decorator
