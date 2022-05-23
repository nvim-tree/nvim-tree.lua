local M = { i = {} }

local function config_symlinks()
  M.i.symlink = #M.config.glyphs.symlink > 0 and M.config.glyphs.symlink .. M.config.padding or ""
  M.i.symlink_arrow = M.config.symlink_arrow
end

local function empty()
  return ""
end

local function get_folder_icon(open, is_symlink, has_children)
  local n
  if is_symlink and open then
    n = M.config.glyphs.folder.symlink_open
  elseif is_symlink then
    n = M.config.glyphs.folder.symlink
  elseif open then
    if has_children then
      n = M.config.glyphs.folder.open
    else
      n = M.config.glyphs.folder.empty_open
    end
  else
    if has_children then
      n = M.config.glyphs.folder.default
    else
      n = M.config.glyphs.folder.empty
    end
  end
  return n .. M.config.padding
end

local function get_file_icon_default()
  local hl_group = "NvimTreeFileIcon"
  local icon = M.config.glyphs.default
  if #icon > 0 then
    return icon .. M.config.padding, hl_group
  else
    return ""
  end
end

local function get_file_icon_webdev(fname, extension)
  local icon, hl_group = M.devicons.get_icon(fname, extension)
  if not M.config.webdev_colors then
    hl_group = "NvimTreeFileIcon"
  end
  if icon and hl_group ~= "DevIconDefault" then
    return icon .. M.config.padding, hl_group
  elseif string.match(extension, "%.(.*)") then
    -- If there are more extensions to the file, try to grab the icon for them recursively
    return get_file_icon_webdev(fname, string.match(extension, "%.(.*)"))
  else
    return get_file_icon_default()
  end
end

local function config_file_icon()
  if M.config.show.file then
    if M.devicons then
      M.get_file_icon = get_file_icon_webdev
    else
      M.get_file_icon = get_file_icon_default
    end
  else
    M.get_file_icon = empty
  end
end

local function config_folder_icon()
  if M.config.show.folder then
    M.get_folder_icon = get_folder_icon
  else
    M.get_folder_icon = empty
  end
end

function M.reset_config()
  config_symlinks()
  config_file_icon()
  config_folder_icon()
end

function M.setup(opts)
  M.config = opts.renderer.icons

  M.devicons = pcall(require, "nvim-web-devicons") and require "nvim-web-devicons"
end

return M
