local api = vim.api
local function sys(v) return vim.fn.system(v) end
local function syslist(v) return vim.fn.systemlist(v) end

local BUF_NAME = '_LuaTree_'

-- TODO: think of a better way to implement the whole thing
-- because right now the code is quite bad
-- I shouldnt base the code on tree indentation to handle logic
-- But for now its a first draft. It works a little

-- TODO: maybe this should not be required, as the tree is only used in dev projects.
-- In the README we should then precise to install vim-rooter.
-- Or maybe we should just keep this functionnality
local function add_dotdot(dirs)
    table.insert(dirs, 1, '..')
    return dirs
end

local dir_struct = add_dotdot(syslist('ls'))

local function open()
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
    api.nvim_command('setlocal nonumber norelativenumber winfixwidth winfixheight')
end

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

local function update_view()
    local buf = get_buf();
    if not buf then return end

    local cursor_pos = api.nvim_win_get_cursor(0)
    api.nvim_buf_set_option(buf, 'modifiable', true)
    api.nvim_buf_set_lines(buf, 1, -1, false, dir_struct)
    api.nvim_buf_set_option(buf, 'modifiable', false)
    api.nvim_win_set_cursor(0, cursor_pos)
end

local function is_dir(path)
    return string.match(sys('ls -l '..path), 'total [0-9].*') ~= nil
end

local function close()
    local win = get_win()
    if not win then return end

    api.nvim_win_close(win, true)
end

local function set_mappings()
    local buf = get_buf()
    if not buf then return end

    local mappings = {
        ['<CR>'] = 'open_file("edit")';
        ['<C-v>'] = 'open_file("vsplit")';
        ['<C-x>'] = 'open_file("split")';
        f = 'find_file()';
    }

    for k,v in pairs(mappings) do
        api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"tree".'..v..'<cr>', {
            nowait = true, noremap = true, silent = true
        })
    end
end

local function update_struct(folder_name)
    local dirs = syslist('ls '..folder_name)

    local index = 0
    for i, v in pairs(dir_struct) do
        if v == folder_name then
            index = i
            break
        end
    end

    if string.match(dir_struct[index + 1] or '', '^  .*$') ~= nil then
        while string.match(dir_struct[index + 1] or '', '^  .*$') ~= nil do
            table.remove(dir_struct, index + 1)
        end
    else
        for i, v in pairs(dirs) do
            table.insert(dir_struct, index+i, '  '..v)
        end
    end
end

local function open_file(open_type)
    local file = api.nvim_get_current_line()

    if is_dir(file) then
        update_struct(file)
        update_view()
    else
        api.nvim_command('wincmd l | '..open_type..' '..file)
    end
end

local function find_file()
    local str = api.nvim_get_current_line()
    print(str)
end

local function win_open()
    return get_buf() ~= nil
end

local function toggle()
    if win_open() == true then
        close()
    else
        open()
        update_view()
        set_mappings()
    end
end

return {
    toggle = toggle;
    open_file = open_file;
    find_file = find_file;
}
