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

---Wrapper around nvim-web-devicons, nils if devicons not available
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

---Wrapper around nvim-web-devicons, nil if devicons not available
---@return DevIcon?
function M.get_default_icon()
  if M.devicons then
    return M.devicons.get_default_icon()
  else
    return nil
  end
end

---Attempt to use nvim-web-devicons if present and enabled for file or folder
---@param opts table
function M.setup(opts)
  if opts.renderer.icons.show.file or opts.renderer.icons.show.folder then
    local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
    if devicons_ok then
      M.devicons = devicons

      -- does nothing if already called i.e. don't clobber previous user setup
      M.devicons.setup()
    end
  end
end

return M
