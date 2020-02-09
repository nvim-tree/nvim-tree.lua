local api = vim.api
local buf, win

local function scratch_buffer()
    buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

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
    win = api.nvim_open_win(buf, true, opts)
    api.nvim_command('setlocal nocursorline winhighlight=Normal:LuaTreePopup')
    api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)
end

local function set_mappings()
    local chars = {
        'a', 'b', 'c', 'd', 'e', 'f', 'h', 'j', 'l', 'q', 'k', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    }
    for _,v in ipairs(chars) do
        api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'i',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'i', '<c-' ..v:upper()..'>', '', { nowait = true, noremap = true, silent = true })
    end
end

local function update_view(...)
    api.nvim_buf_set_lines(buf, 0, -1, false, ...)
    api.nvim_command('normal G')
    api.nvim_command('startinsert!')
end

local function wrapper(...)
    scratch_buffer()
    update_view(...)
    set_mappings()
end

local function add_file(path)
    wrapper({ "Create File", path })
end

local function remove_file(filename, path, isdir)
    local name = "File"
    if isdir == true then name = "Directory" end
    wrapper({ "Remove " .. name .. " " .. filename .. " ?",  "y/n: " })
end

local function rename_file(filename, path, isdir)
    local name = "File"
    if isdir == true then name = "Directory" end
    wrapper({ "Rename " .. name, path .. filename })
end

return {
    add_file = add_file;
    remove_file = remove_file;
    rename_file = rename_file;
}
