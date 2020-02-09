local lib_file = require 'lib/file'
local format = require 'lib/format'.format_tree

local api = vim.api
local function sys(v) return api.nvim_call_function('system', { v }) end
local function syslist(v) return api.nvim_call_function('systemlist', { v }) end

-- get rid of \n and add leading '/'
local ROOT_PATH = string.sub(sys('pwd'), 1, -2) .. '/'
local BUF_NAME = '_LuaTree_'

local function is_dir(path)
    local stat = vim.loop.fs_stat(path)
    return stat and stat.type == 'directory' or false
end

local function sort_dirs(dirs)
    local sorted_tree = {}
    for _, node in pairs(dirs) do
        if node.dir == true then
            table.insert(sorted_tree, 1, node)
        else
            table.insert(sorted_tree, node)
        end
    end

    return sorted_tree
end

local function create_dirs(path, depth, dirs)
    local tree = {}

    if not string.find(path, '^.*/$') then path = path .. '/' end

    for i, name in pairs(dirs) do
        tree[i] = {
            path = path,
            name = name,
            depth = depth,
            dir = is_dir(path .. name),
            open = false -- only relevant when its a dir
        }
    end

    return sort_dirs(tree)
end

local Tree = create_dirs(ROOT_PATH, 0, syslist('ls'))

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

local function buf_setup()
    api.nvim_command('setlocal nonumber norelativenumber winfixwidth winfixheight')
    api.nvim_command('setlocal winhighlight=EndOfBuffer:LuaTreeEndOfBuffer')
end

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
    buf_setup()
    api.nvim_command('echo "'..ROOT_PATH..'"')
end

local function close()
    local win = get_win()
    if not win then return end

    api.nvim_win_close(win, true)
end

local function update_view()
    local buf = get_buf();
    if not buf then return end

    local cursor_pos = api.nvim_win_get_cursor(0)
    api.nvim_buf_set_option(buf, 'modifiable', true)
    api.nvim_buf_set_lines(buf, 0, -1, false, format(Tree))
    api.nvim_buf_set_option(buf, 'modifiable', false)
    api.nvim_win_set_cursor(0, cursor_pos)
end

local function is_win_open()
    return get_buf() ~= nil
end

local function open_file(open_type)
    local tree_index = api.nvim_win_get_cursor(0)[1]
    local node = Tree[tree_index]

    if node.dir == true then
        local index = tree_index + 1;
        node.open = not node.open
        local next_node = Tree[index]
        if next_node ~= nil and next_node.depth > node.depth then
            while next_node ~= nil and next_node.depth ~= node.depth do
                table.remove(Tree, index)
                next_node = Tree[index]
            end
        else
            local dirlist = syslist('ls ' .. node.path .. node.name)
            local child_dirs = create_dirs(node.path .. node.name .. '/', node.depth + 1, dirlist)
            for i, n in pairs(child_dirs) do
                table.insert(Tree, tree_index + i, n)
            end
        end

        update_view()
    else
        api.nvim_command('wincmd l | '..open_type..' '.. node.path .. node.name)
    end
end

local function set_mappings()
    local buf = get_buf()
    if not buf then return end

    local mappings = {
        ['<CR>'] = 'open_file("edit")';
        ['<C-v>'] = 'open_file("vsplit")';
        ['<C-x>'] = 'open_file("split")';
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

    local maps = {
        j = 'j$B',
        k = 'k$B',
        l = '<Nop>',
        h = '<Nop>'
    }

    for k,v in pairs(maps) do
        api.nvim_buf_set_keymap(buf, 'n', k, v, {
            nowait = true, noremap = true, silent = true
        })
    end
end

local function toggle()
    if is_win_open() == true then
        close()
    else
        open()
        update_view()
        set_mappings()
    end
end

local function edit_file(edit_type)
    local tree_index = api.nvim_win_get_cursor(0)[1]
    local node = Tree[tree_index]

    if edit_type == 'add' then
        if node.dir == true then
            lib_file.add_file(node.path .. node.name .. '/')
        else
            lib_file.add_file(node.path)
        end
    elseif edit_type == 'delete' then
        lib_file.remove_file(node.name, node.path, node.dir)
    elseif edit_type == 'rename' then
        lib_file.rename_file(node.name, node.path, node.dir)
    end
end

return {
    toggle = toggle;
    open_file = open_file;
    edit_file = edit_file;
}

