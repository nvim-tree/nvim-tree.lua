local api = vim.api

local libformat = require 'lib/format'
local format = libformat.format_tree
local highlight = libformat.highlight_buffer

local stateutils = require 'lib/state'
local get_tree = stateutils.get_tree

local confutils = require 'lib/conf'
local get_buf_name = confutils.get_buf_name
local get_root_path = confutils.get_root_path

local function get_buf()
    local BUF_NAME = get_buf_name()
    local regex = '.*'..BUF_NAME..'$';

    for _, win in pairs(api.nvim_list_wins()) do
        local buf = api.nvim_win_get_buf(win)
        local buf_name = api.nvim_buf_get_name(buf)

        if string.match(buf_name, regex) ~= nil then return buf end
    end

    return nil
end

local function get_win()
    local BUF_NAME = get_buf_name()
    local regex = '.*'..BUF_NAME..'$';

    for _, win in pairs(api.nvim_list_wins()) do
        local buf_name = api.nvim_buf_get_name(api.nvim_win_get_buf(win))
        if string.match(buf_name, regex) ~= nil then return win end
    end

    return nil
end

local function buf_setup()
    api.nvim_command('setlocal nonumber norelativenumber winfixwidth winfixheight')
    api.nvim_command('setlocal winhighlight=EndOfBuffer:LuaTreeEndOfBuffer')
end

local function open()
    local BUF_NAME = get_buf_name()
    local ROOT_PATH = get_root_path()
    local win_width = 30
    local options = {
        bufhidden = 'wipe';
        buftype = 'nowrite';
        modifiable = false;
    }

    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(buf, BUF_NAME)

    for opt, val in pairs(options) do
        api.nvim_buf_set_option(buf, opt, val)
    end

    api.nvim_command('topleft '..win_width..'vnew')
    api.nvim_win_set_buf(0, buf)
    buf_setup()
    api.nvim_command('echo "'..ROOT_PATH..'"')
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


local function is_win_open()
    return get_buf() ~= nil
end

local function set_mappings()
    local buf = get_buf()
    if not buf then return end

    local mappings = {
        ['<CR>'] = 'open_file("edit")';
        ['<2-LeftMouse>'] = 'open_file("edit")';
        ['<C-v>'] = 'open_file("vsplit")';
        ['<C-x>'] = 'open_file("split")';
        ['<C-[>'] = 'open_file("chdir")';
        a = 'edit_file("add")';
        d = 'edit_file("delete")';
        r = 'edit_file("rename")';
        f = 'find_file()';
    }

    for k,v in pairs(mappings) do
        api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"tree".'..v..'<cr>', {
            nowait = true, noremap = true, silent = true
        })
    end
end

return {
    open = open;
    close = close;
    is_win_open = is_win_open;
    update_view = update_view;
    get_buf = get_buf;
    get_win = get_win;
    set_mappings = set_mappings;
}
