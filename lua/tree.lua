local dir_struct = vim.fn.systemlist('ls')
local sys = function(v) vim.fn.system(v) end
local syslist = function(v) vim.fn.systemlist(v) end
local api = vim.api
local buf = nil
local win = nil

local function open()
    local win_width = 30
    local options = {
        bufhidden = 'wipe';
        buftype = 'nowrite';
        modifiable = false;
    }

    buf = api.nvim_create_buf(false, true)

    for opt, val in pairs(options) do
        api.nvim_buf_set_option(buf, opt, val)
    end

    api.nvim_command('topleft '..win_width..'vnew | set nonumber norelativenumber')
    win = api.nvim_win_get_number(0)
    api.nvim_win_set_buf(win, buf)
end

local function update_view()
    api.nvim_buf_set_option(buf, 'modifiable', true)
    api.nvim_buf_set_lines(buf, 1, -1, false, dir_struct)
    api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function is_dir(path)
    return string.match(sys('ls -l '..path), 'total [0-9].*') ~= nil
end

local function close()
    api.nvim_win_close(win, true)
    win = nil
    buf = nil
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
    return false
end

local function toggle()
    if win_open() then
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
