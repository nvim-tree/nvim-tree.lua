local api = vim.api

local function get(var, fallback)
    if vim.api.nvim_call_function('exists', { var }) == 1 then
        return vim.api.nvim_get_var(var)
    else
        return fallback
    end
end

local HAS_DEV_ICONS = api.nvim_call_function('exists', { "*WebDevIconsGetFileTypeSymbol" }) == 1

local SHOW_FOLDER_ICON = get('lua_tree_show_folders', 1) == 1

local SHOW_GIT_ICON = get('lua_tree_show_git_icons', 1) == 1

local colors = {
    red = get('terminal_color_1', 'Red'),
    green = get('terminal_color_2', 'Green'),
    yellow = get('terminal_color_3', 'Yellow'),
    blue = get('terminal_color_4', 'Blue'),
    purple = get('terminal_color_5', 'Purple'),
    cyan = get('terminal_color_6', 'Cyan'),
    orange = get('terminal_color_11', 'Orange'),
    dark_red = get('terminal_color_9', 'DarkRed'),
}
return {
    SHOW_FOLDER_ICON = SHOW_FOLDER_ICON,
    HAS_DEV_ICONS = HAS_DEV_ICONS,
    SHOW_GIT_ICON = SHOW_GIT_ICON,
    colors = colors
}

