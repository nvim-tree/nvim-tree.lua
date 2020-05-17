local api = vim.api

local M = {}

local function get(var, fallback)
  if api.nvim_call_function('exists', { var }) == 1 then
    return api.nvim_get_var(var)
  else
    return fallback
  end
end

local function get_color_from_hl(hl_name, fallback)
  local id = api.nvim_get_hl_id_by_name(hl_name)
  if not id then return fallback end

  local hl = api.nvim_get_hl_by_id(id, true)
  if not hl or not hl.foreground then return fallback end

  return hl.foreground
end

local HAS_DEV_ICONS = api.nvim_call_function('exists', { "*WebDevIconsGetFileTypeSymbol" }) == 1

local show_icons = get('lua_tree_show_icons', { git = 1, folders = 1, files = 1 })

M.SHOW_FILE_ICON = HAS_DEV_ICONS and show_icons.files == 1
M.SHOW_FOLDER_ICON = show_icons.folders == 1
M.SHOW_GIT_ICON = show_icons.git == 1

function M.get_colors()
  return {
    red = get('terminal_color_1', get_color_from_hl('Keyword', 'Red')),
    green = get('terminal_color_2', get_color_from_hl('Character', 'Green')),
    yellow = get('terminal_color_3', get_color_from_hl('PreProc', 'Yellow')),
    blue = get('terminal_color_4', get_color_from_hl('Include', 'Blue')),
    purple = get('terminal_color_5', get_color_from_hl('Define', 'Purple')),
    cyan = get('terminal_color_6', get_color_from_hl('Conditional', 'Cyan')),
    orange = get('terminal_color_11', get_color_from_hl('Number', 'Orange')),
    dark_red = get('terminal_color_9', get_color_from_hl('Keyword', 'DarkRed')),
  }
end

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
