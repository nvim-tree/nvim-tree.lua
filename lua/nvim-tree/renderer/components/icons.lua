---@class DevIcon
---@field icon string
---@field color string
---@field cterm_color string
---@field name string

---@class DevIcons
---@field get_icon fun(name: string, ext: string?): string?, string?
---@field get_default_icon fun(): DevIcon

local M = {
  i = {},
  ---@type DevIcons?
  devicons = nil,
}

local function config_symlinks()
  M.i.symlink = #M.config.glyphs.symlink > 0 and M.config.glyphs.symlink or ""
  M.i.symlink_arrow = M.config.symlink_arrow
end

---@return string icon
---@return string? hl_group
local function empty()
  return "", nil
end

---@return string icon
---@return string? hl_group
local function get_file_icon_default()
  local hl_group = "NvimTreeFileIcon"
  local icon = M.config.glyphs.default
  if #icon > 0 then
    return icon, hl_group
  else
    return "", nil
  end
end

---@param name string
---@param ext string
---@return string icon
---@return string? hl_group
local function get_file_icon_webdev(name, ext)
  local icon, hl_group = M.devicons.get_icon(name, ext)
  if not M.config.web_devicons.file.color then
    hl_group = "NvimTreeFileIcon"
  end
  if icon and hl_group ~= "DevIconDefault" then
    return icon, hl_group
  elseif string.match(ext, "%.(.*)") then
    -- If there are more extensions to the file, try to grab the icon for them recursively
    return get_file_icon_webdev(name, string.match(ext, "%.(.*)"))
  else
    local devicons_default = M.devicons.get_default_icon()
    if devicons_default and type(devicons_default.icon) == "string" and type(devicons_default.name) == "string" then
      return devicons_default.icon, "DevIcon" .. devicons_default.name
    else
      return get_file_icon_default()
    end
  end
end

local function config_file_icon()
  if M.config.show.file then
    if M.devicons and M.config.web_devicons.file.enable then
      M.get_file_icon = get_file_icon_webdev
    else
      M.get_file_icon = get_file_icon_default
    end
  else
    M.get_file_icon = empty
  end
end

---Wrapper around nvim-web-devicons, nil if not present
---@param name string
---@param ext string?
---@return string? icon
---@return string? hl_group
function M.get_icon(name, ext)
  if M.devicons then
    return M.devicons.get_icon(name, ext)
  end
end

function M.reset_config()
  config_symlinks()
  config_file_icon()
end

function M.setup(opts)
  M.config = opts.renderer.icons

  M.devicons = pcall(require, "nvim-web-devicons") and require("nvim-web-devicons") or nil
end

return M
