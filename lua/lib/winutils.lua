local api = vim.api

local libformat = require 'lib/format'
local format = libformat.format_tree
local highlight = libformat.highlight_buffer

local stateutils = require 'lib/state'
local get_tree = stateutils.get_tree

local confutils = require 'lib/conf'
local get_buf_name = confutils.get_buf_name
local get_root_path = confutils.get_root_path

local scratch_buf = nil

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

local function scratch_buffer()
    scratch_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(scratch_buf, 'bufhidden', 'wipe')

    local width = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")

    local win_height = 2
    local win_width = 90

    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col
    }

    local border_buf = api.nvim_create_buf(false, true)

    local border_opts = {
        style = "minimal",
        relative = "editor",
        width = win_width + 2,
        height = win_height + 2,
        row = row - 1,
        col = col - 1
    }

    local border_lines = { '┌' .. string.rep('─', win_width) .. '┐' }
    local middle_line = '│' .. string.rep(' ', win_width) .. '│'
    for _ = 1, win_height do
        table.insert(border_lines, middle_line)
    end
    table.insert(border_lines, '└' .. string.rep('─', win_width) .. '┘')
    api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

    api.nvim_open_win(border_buf, true, border_opts)
    api.nvim_command('setlocal nocursorline winhighlight=Normal:LuaNoEndOfBufferPopup')
    api.nvim_open_win(scratch_buf, true, opts)
    api.nvim_command('setlocal nocursorline winhighlight=Normal:LuaTreePopup')
    api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)
end

local function set_scratch_mappings(edit_type)
    local chars = {
        'a', 'b', 'd', 'e', 'f', 'h', 'l', 'j', 'q', 'k', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    }
    for _,v in ipairs(chars) do
        api.nvim_buf_set_keymap(scratch_buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(scratch_buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(scratch_buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(scratch_buf, 'i',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(scratch_buf, 'i', '<c-' ..v:upper()..'>', '', { nowait = true, noremap = true, silent = true })
    end

    if edit_type == 'add' then
        api.nvim_buf_set_keymap(scratch_buf, 'i', '<CR>', "<esc>:lua require'lib/file'.add_file(vim.api.nvim_get_current_line())<CR>", { nowait = true, noremap = true, silent = true })
    elseif edit_type == 'rename' then
        api.nvim_buf_set_keymap(scratch_buf, 'i', '<CR>', "<esc>:lua require'lib/file'.rename_file(vim.api.nvim_get_current_line())<CR>", { nowait = true, noremap = true, silent = true })
    elseif edit_type == 'delete' then
        api.nvim_buf_set_keymap(scratch_buf, 'i', '<CR>', "<esc>:lua require'lib/file'.remove_file(vim.api.nvim_get_current_line())<CR>", { nowait = true, noremap = true, silent = true })
    end
    api.nvim_buf_set_keymap(scratch_buf, 'i', '<esc>', "<esc>:q!<CR>", { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(scratch_buf, 'i', '<C-c>', "<esc>:q!<CR>", { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(scratch_buf, 'i', '<C-[>', "<esc>:q!<CR>", { nowait = true, noremap = true, silent = true })
end

local function update_scratch_view(...)
    api.nvim_buf_set_lines(scratch_buf, 0, -1, false, ...)
    api.nvim_command('normal G')
    api.nvim_command('startinsert!')
end

local function scratch_wrapper(edit_type, ...)
    scratch_buffer()
    update_scratch_view(...)
    set_scratch_mappings(edit_type)
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
    scratch_wrapper = scratch_wrapper;
}
