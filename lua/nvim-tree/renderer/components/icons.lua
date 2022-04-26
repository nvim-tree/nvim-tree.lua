local icon_config = require "nvim-tree.renderer.icon-config"

local M = { i = {} }

local function config_symlinks()
  M.i.symlink = #M.icons.symlink > 0 and M.icons.symlink .. M.padding or ""
  M.i.symlink_arrow = vim.g.nvim_tree_symlink_arrow or " ➛ "
end

local function empty()
  return ""
end

local function get_trailing_length()
  return vim.g.nvim_tree_add_trailing and 1 or 0
end

local function set_folder_hl_default(line, depth, git_icon_len, _, hl_group, _, hl)
  table.insert(hl, { hl_group, line, depth + git_icon_len, -1 })
end

local function get_folder_icon(open, is_symlink, has_children)
  local n
  if is_symlink and open then
    n = M.icons.folder_icons.symlink_open
  elseif is_symlink then
    n = M.icons.folder_icons.symlink
  elseif open then
    if has_children then
      n = M.icons.folder_icons.open
    else
      n = M.icons.folder_icons.empty_open
    end
  else
    if has_children then
      n = M.icons.folder_icons.default
    else
      n = M.icons.folder_icons.empty
    end
  end
  return n .. M.padding
end

local function set_folder_hl(line, depth, icon_len, name_len, hl_icongroup, hl_fnamegroup, hl, should_hl_opened_files)
  local hl_icon = should_hl_opened_files and hl_icongroup or "NvimTreeFolderIcon"
  table.insert(hl, { hl_icon, line, depth, depth + icon_len })
  table.insert(hl, { hl_fnamegroup, line, depth + icon_len, depth + icon_len + name_len + get_trailing_length() })
end

local function get_file_icon_default()
  local hl_group = "NvimTreeFileIcon"
  local icon = M.icons.default
  if #icon > 0 then
    return icon .. M.padding, hl_group
  else
    return ""
  end
end

local function get_file_icon_webdev(fname, extension)
  local icon, hl_group = M.devicons.get_icon(fname, extension)
  if not M.webdev_colors then
    hl_group = "NvimTreeFileIcon"
  end
  if icon and hl_group ~= "DevIconDefault" then
    return icon .. M.padding, hl_group
  elseif string.match(extension, "%.(.*)") then
    -- If there are more extensions to the file, try to grab the icon for them recursively
    return get_file_icon_webdev(fname, string.match(extension, "%.(.*)"))
  else
    return get_file_icon_default()
  end
end

local function config_file_icon()
  if M.configs.show_file_icon then
    if M.devicons then
      M.get_file_icon = get_file_icon_webdev
    else
      M.get_file_icon = get_file_icon_default
    end
  else
    M.get_file_icon = empty
  end
end

local function config_special_icon()
  if M.configs.show_file_icon then
    M.i.special = #M.icons.default > 0 and M.icons.default .. M.padding or ""
  else
    M.i.special = ""
  end
end

local function config_folder_icon()
  if M.configs.show_folder_icon then
    M.get_folder_icon = get_folder_icon
    M.set_folder_hl = set_folder_hl
  else
    M.get_folder_icon = empty
    M.set_folder_hl = set_folder_hl_default
  end
end

function M.reset_config(webdev_colors)
  M.configs = icon_config.get_config()
  M.icons = M.configs.icons
  M.padding = vim.g.nvim_tree_icon_padding or " "
  M.devicons = M.configs.has_devicons and require "nvim-web-devicons" or nil
  M.webdev_colors = webdev_colors

  config_symlinks()
  config_special_icon()
  config_file_icon()
  config_folder_icon()
end

return M
