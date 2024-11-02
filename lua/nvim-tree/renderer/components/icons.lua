---@class DevIcon
---@field icon string
---@field color string
---@field cterm_color string
---@field name string

---@class DevIcons
---@field get_icon fun(name: string, ext: string?): string?, string?
---@field get_default_icon fun(): DevIcon

local M = {
  ---@type DevIcons?
  devicons = nil,
}

---Wrapper around nvim-web-devicons, nils if not present
---@param name string
---@return string? icon
---@return string? hl_group
function M.get_icon(name)
  if M.devicons then
    return M.devicons.get_icon(name, nil)
  else
    return nil, nil
  end
end

function M.setup()
  local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
  if devicons_ok then
    M.devicons = devicons
  end
end

return M
