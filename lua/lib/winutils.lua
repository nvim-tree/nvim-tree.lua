local BUF_NAME = 'LuaTree'
local api = vim.api

local libformat = require 'lib/format'
local format = libformat.format_tree
local highlight = libformat.highlight_buffer

local stateutils = require 'lib/state'
local get_tree = stateutils.get_tree

local function get_buf()
    local regex = '.*'..BUF_NAME..'$';

    for _, win in pairs(api.nvim_list_wins()) do
        local buf = api.nvim_win_get_buf(win)
        local buf_name = api.nvim_buf_get_name(buf)

        if string.match(buf_name, regex) ~= nil then return buf end
    end

    return nil
end

local function get_win()
    local regex = '.*'..BUF_NAME..'$';

    for _, win in pairs(api.nvim_list_wins()) do
        local buf_name = api.nvim_buf_get_name(api.nvim_win_get_buf(win))
        if string.match(buf_name, regex) ~= nil then return win end
    end

    return nil
end

local BUF_OPTIONS = {
    'nowrap', 'sidescroll=5', 'nospell', 'nolist', 'nofoldenable',
    'foldmethod=manual', 'foldcolumn=0', 'nonumber', 'norelativenumber',
    'winfixwidth', 'winfixheight', 'noswapfile', 'bufhidden=wipe',
    'splitbelow', 'splitright', 'winhighlight=EndOfBuffer:LuaTreeEndOfBuffer',
    'noshowmode', 'noruler', 'noshowcmd',
}

local WIN_WIDTH = 30
local SIDE = 'H'

if api.nvim_call_function('exists', { 'g:lua_tree_width' }) == 1 then
    WIN_WIDTH = api.nvim_get_var('lua_tree_width')
end

if api.nvim_call_function('exists', { 'g:lua_tree_side' }) == 1 then
    if api.nvim_get_var('lua_tree_side') == 'right' then
        SIDE = 'L'
    end
end

local function open()
    local options = {
        bufhidden = 'delete';
        buftype = 'nowrite';
        modifiable = false;
    }

    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(buf, BUF_NAME)

    for opt, val in pairs(options) do
        api.nvim_buf_set_option(buf, opt, val)
    end

    api.nvim_command('vnew')
    api.nvim_command('wincmd '..SIDE)
    api.nvim_command('vertical resize '..WIN_WIDTH)
    api.nvim_win_set_buf(0, buf)
    for _, opt in pairs(BUF_OPTIONS) do
        api.nvim_command('setlocal '..opt)
    end
end

local function replace_tree()
    local win = get_win()
    if not win then return end

    local tree_position = api.nvim_win_get_position(win)
    local win_width = api.nvim_win_get_width(win)
    if win_width == WIN_WIDTH then
        if SIDE == 'H' and tree_position[2] == 0 then return end
        local columns = api.nvim_get_option('columns')
        if SIDE == 'L' and tree_position[2] ~= columns - win_width then return end
    end

    local current_win = api.nvim_get_current_win()

    api.nvim_set_current_win(win)
    api.nvim_command('wincmd '..SIDE)
    api.nvim_command('vertical resize '..WIN_WIDTH)

    api.nvim_set_current_win(current_win)
end

local function close()
    local win = get_win()
    if not win then return end

    api.nvim_win_close(win, true)
end

local function update_view(update_cursor)
    local buf = get_buf();
    if not buf then return end

    local cursor = api.nvim_win_get_cursor(0)
    local tree = get_tree()

    api.nvim_buf_set_option(buf, 'modifiable', true)
    api.nvim_buf_set_lines(buf, 0, -1, false, format(tree))
    highlight(buf, tree)
    api.nvim_buf_set_option(buf, 'modifiable', false)

    if update_cursor == true then
        api.nvim_win_set_cursor(0, cursor)
    end
end

local function set_mappings()
    local buf = get_buf()
    if not buf then return end

    local mappings = {
        ['<CR>'] = 'open_file("edit")';
        ['<2-LeftMouse>'] = 'open_file("edit")';
        ['<2-RightMouse>'] = 'open_file("chdir")';
        ['<C-v>'] = 'open_file("vsplit")';
        ['<C-x>'] = 'open_file("split")';
        ['<C-t>'] = 'open_file("tabnew")';
        ['.'] = 'open_file("chdir")';
        a = 'edit_file("create")';
        d = 'edit_file("remove")';
        r = 'edit_file("rename")';
    }

    for k,v in pairs(mappings) do
        api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"tree".'..v..'<cr>', {
            nowait = true, noremap = true, silent = true
        })
    end
end

local function is_win_open()
    return get_buf() ~= nil
end

return {
    open = open;
    close = close;
    is_win_open = is_win_open;
    update_view = update_view;
    get_buf = get_buf;
    get_win = get_win;
    set_mappings = set_mappings;
    replace_tree = replace_tree;
}
