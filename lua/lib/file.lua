local api = vim.api
local buf, win
local system = function(v) api.nvim_call_function('system', { v }) end
-- local update_tree_view = require ''
local update_tree_state = require 'lib/state'.update_tree

local EDIT_FILE = nil

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

local function set_mappings(edit_type)
    local chars = {
        'a', 'b', 'd', 'e', 'f', 'h', 'l', 'j', 'q', 'k', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    }
    for _,v in ipairs(chars) do
        api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'i',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'i', '<c-' ..v:upper()..'>', '', { nowait = true, noremap = true, silent = true })
    end

    if edit_type == 'add' then
        api.nvim_buf_set_keymap(buf, 'i', '<CR>', "<esc>:lua require'lib/file'.add_file(vim.api.nvim_get_current_line())<CR>", { nowait = true, noremap = true, silent = true })
    elseif edit_type == 'rename' then
        api.nvim_buf_set_keymap(buf, 'i', '<CR>', "<esc>:lua require'lib/file'.rename_file(vim.api.nvim_get_current_line())<CR>", { nowait = true, noremap = true, silent = true })
    elseif edit_type == 'delete' then
        api.nvim_buf_set_keymap(buf, 'i', '<CR>', "<esc>:lua require'lib/file'.remove_file(vim.api.nvim_get_current_line())<CR>", { nowait = true, noremap = true, silent = true })
    end
    api.nvim_buf_set_keymap(buf, 'i', '<esc>', "<esc>:q!<CR>", { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'i', '<C-c>', "<esc>:q!<CR>", { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'i', '<C-[>', "<esc>:q!<CR>", { nowait = true, noremap = true, silent = true })
end

local function update_view(...)
    api.nvim_buf_set_lines(buf, 0, -1, false, ...)
    api.nvim_command('normal G')
    api.nvim_command('startinsert!')
end

local function wrapper(edit_type, ...)
    scratch_buffer()
    update_view(...)
    set_mappings(edit_type)
end

local function edit_add(path)
    wrapper("add", { "Create File", path })
end

local function edit_remove(filename, path)
    EDIT_FILE = path .. filename
    wrapper("delete", { "Remove " .. filename .. " ?",  "y/n: " })
end

local function edit_rename(filename, path)
    EDIT_FILE = path .. filename
    wrapper("rename", { "Rename " .. path, path .. filename })
end

local function add_file(path)
    if string.match(path, '.*/$') then
        system('mkdir -p ' .. path)
    else
        system('touch ' .. path)
    end
    api.nvim_command("q!")
    update_tree_state()
    update_tree_view(true)
end

local function remove_file(confirmation)
    if string.match(confirmation, '^y/n: y.*$') ~= nil then
        system('rm -rf ' .. EDIT_FILE)
    end
    EDIT_FILE = nil
    api.nvim_command("q!")
    update_tree_state()
    update_tree_view(true)
end

local function rename_file(path)
    system('mv '..EDIT_FILE..' '..path)
    EDIT_FILE = nil
    api.nvim_command("q!")
    update_tree_state()
    update_tree_view(true)
end

return {
    edit_add = edit_add;
    edit_remove = edit_remove;
    edit_rename = edit_rename;
    add_file = add_file;
    remove_file = remove_file;
    rename_file = rename_file;
}
