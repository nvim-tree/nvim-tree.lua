local Class = require("nvim-tree.classic")

--- #TODO 3241 split this into abstract interface for API and concrete to return to user

---Abstract Decorator
---@class (exact) Decorator: Class
---@field protected enabled boolean
---@field protected highlight_range nvim_tree.api.decorator.highlight_range
---@field protected icon_placement nvim_tree.api.decorator.icon_placement
local Decorator = Class:extend()

---@class (exact) DecoratorArgs
---@field explorer Explorer

---Abstract icon override, optionally implemented
---@param node Node
---@return nvim_tree.api.decorator.highlighted_string? icon_node
function Decorator:icon_node(node)
  return self:nop(node)
end

---Abstract icons, optionally implemented
---@protected
---@param node Node
---@return nvim_tree.api.decorator.highlighted_string[]? icons
function Decorator:icons(node)
  self:nop(node)
end

---Abstract highlight group, optionally implemented
---@protected
---@param node Node
---@return string? highlight_group
function Decorator:highlight_group(node)
  self:nop(node)
end

---Maybe highlight groups for icon and name
---@param node Node
---@return string? icon highlight group
---@return string? name highlight group
function Decorator:highlight_group_icon_name(node)
  local icon_hl, name_hl

  if self.enabled and self.highlight_range ~= "none" then
    local hl = self:highlight_group(node)

    if self.highlight_range == "all" or self.highlight_range == "icon" then
      icon_hl = hl
    end
    if self.highlight_range == "all" or self.highlight_range == "name" then
      name_hl = hl
    end
  end

  return icon_hl, name_hl
end

---Maybe icon sign
---@param node Node
---@return string? name
function Decorator:sign_name(node)
  if not self.enabled or self.icon_placement ~= "signcolumn" then
    return
  end

  local icons = self:icons(node)
  if icons and #icons > 0 then
    return icons[1].hl[1]
  end
end

---Icons when "before"
---@param node Node
---@return nvim_tree.api.decorator.highlighted_string[]? icons
function Decorator:icons_before(node)
  if not self.enabled or self.icon_placement ~= "before" then
    return
  end

  return self:icons(node)
end

---Icons when "after"
---@param node Node
---@return nvim_tree.api.decorator.highlighted_string[]? icons
function Decorator:icons_after(node)
  if not self.enabled or self.icon_placement ~= "after" then
    return
  end

  return self:icons(node)
end

---Icons when "right_align"
---@param node Node
---@return nvim_tree.api.decorator.highlighted_string[]? icons
function Decorator:icons_right_align(node)
  if not self.enabled or self.icon_placement ~= "right_align" then
    return
  end

  return self:icons(node)
end

---Define a sign
---@protected
---@param icon nvim_tree.api.decorator.highlighted_string?
function Decorator:define_sign(icon)
  if icon and #icon.hl > 0 then
    local name = icon.hl[1]

    if not vim.tbl_isempty(vim.fn.sign_getdefined(name)) then
      vim.fn.sign_undefine(name)
    end

    -- don't render sign if empty
    if #icon.str < 1 then
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
