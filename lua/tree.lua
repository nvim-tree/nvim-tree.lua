local api = vim.api
local function sys(v) return vim.fn.system(v) end
local function syslist(v) return vim.fn.systemlist(v) end

local dir_struct = syslist('ls')
local BUF_NAME = 'LuaTree'
print(dir_struct)

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

    api.nvim_command('topleft '..win_width..'vnew | set nonumber norelativenumber')
    api.nvim_win_set_buf(0, buf)
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
    if buf == nil then return end

    api.nvim_buf_set_option(buf, 'modifiable', true)
    api.nvim_buf_set_lines(buf, 1, -1, false, dir_struct)
    api.nvim_buf_set_option(buf, 'modifiable', false)
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

local function open_file(open_type)
    local str = api.nvim_get_current_line()
    if is_dir(str) then
        local cur_dir = syslist('ls')
        local sub_dir = syslist('ls')
        -- local final_data = {}

        update_view()
    else
        print(open_type)
        -- api.nvim_command(open_type..' '..str)
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
