local M = { i = {} }

local function config_symlinks()
  M.i.symlink = #M.config.glyphs.symlink > 0 and M.config.glyphs.symlink or ""
  M.i.symlink_arrow = M.config.symlink_arrow
end

local function empty()
  return ""
end

local function get_folder_icon_default(node, has_children)
  local is_symlink = node.links_to ~= nil
  local n
  if is_symlink and node.open then
    n = M.config.glyphs.folder.symlink_open
  elseif is_symlink then
    n = M.config.glyphs.folder.symlink
  elseif node.open then
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
  return n, nil
end

local function get_folder_icon_webdev(node, has_children)
  local icon, hl_group = M.devicons.get_icon(node.name, node.extension)
  if not M.config.web_devicons.folder.color then
    hl_group = nil
  end
  if icon ~= nil then
    return icon, hl_group
  else
    return get_folder_icon_default(node, has_children)
  end
end

local function get_file_icon_default()
  local hl_group = "NvimTreeFileIcon"
  local icon = M.config.glyphs.default
  if #icon > 0 then
    return icon, hl_group
  else
    return ""
  end
end

local function get_file_icon_webdev(fname, extension)
  local icon, hl_group = M.devicons.get_icon(fname, extension)
  if not M.config.web_devicons.file.color then
    hl_group = "NvimTreeFileIcon"
  end
  if icon and hl_group ~= "DevIconDefault" then
    return icon, hl_group
  elseif string.match(extension, "%.(.*)") then
    -- If there are more extensions to the file, try to grab the icon for them recursively
    return get_file_icon_webdev(fname, string.match(extension, "%.(.*)"))
  else
    return get_file_icon_default()
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

local function config_folder_icon()
  if M.config.show.folder then
    if M.devicons and M.config.web_devicons.folder.enable then
      M.get_folder_icon = get_folder_icon_webdev
    else
      M.get_folder_icon = get_folder_icon_default
    end
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

  M.devicons = pcall(require, "nvim-web-devicons") and require "nvim-web-devicons" or nil
end

return M
