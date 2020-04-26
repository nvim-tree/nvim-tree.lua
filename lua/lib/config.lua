local api = vim.api

local M = {}

local function get(var, fallback)
  if api.nvim_call_function('exists', { var }) == 1 then
    return api.nvim_get_var(var)
  else
    return fallback
  end
end

local HAS_DEV_ICONS = api.nvim_call_function('exists', { "*WebDevIconsGetFileTypeSymbol" }) == 1

local show_icons = get('lua_tree_show_icons', { git = 1, folders = 1, files = 1 })

M.SHOW_FILE_ICON = HAS_DEV_ICONS and show_icons.files == 1
M.SHOW_FOLDER_ICON = show_icons.folders == 1
M.SHOW_GIT_ICON = show_icons.git == 1

M.colors = {
  red = get('terminal_color_1', 'Red'),
  green = get('terminal_color_2', 'Green'),
  yellow = get('terminal_color_3', 'Yellow'),
  blue = get('terminal_color_4', 'Blue'),
  purple = get('terminal_color_5', 'Purple'),
  cyan = get('terminal_color_6', 'Cyan'),
  orange = get('terminal_color_11', 'Orange'),
  dark_red = get('terminal_color_9', 'DarkRed'),
}

local keybindings = get('lua_tree_bindings', {});

M.bindings = {
  edit = keybindings.edit or '<CR>',
  edit_vsplit = keybindings.edit_vsplit or '<C-v>',
  edit_split = keybindings.edit_split or '<C-x>',
  edit_tab = keybindings.edit_tab or '<C-t>',
  cd = keybindings.cd or '.',
  create = keybindings.create or 'a',
  remove = keybindings.remove or 'd',
  rename = keybindings.rename or 'r',
}

return M
