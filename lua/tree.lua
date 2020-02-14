local lib_file = require 'lib/file'
local format = require 'lib/format'.format_tree
local highlight = require 'lib/format'.highlight_buffer

local api = vim.api
local function syslist(v) return api.nvim_call_function('systemlist', { v }) end

local ROOT_PATH = vim.loop.cwd() .. '/'
local Tree = {}
local BUF_NAME = '_LuaTree_'

local function is_dir(path)
    local stat = vim.loop.fs_stat(path)
    return stat and stat.type == 'directory' or false
end

local function check_dir_access(path)
    return vim.loop.fs_access(path, 'R') == true
end

local function list_dirs(path)
    local ls_cmd = 'ls -A --ignore=.git '
    if path == nil then
        return syslist(ls_cmd)
    elseif check_dir_access(path) == false then
        -- TODO: display an error here (permission denied)
        return {}
    else
        return syslist(ls_cmd .. path)
    end
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

local function create_nodes(path, depth, dirs)
    local tree = {}

    if not string.find(path, '^.*/$') then path = path .. '/' end

    for i, name in pairs(dirs) do
        tree[i] = {
            path = path,
            name = name,
            depth = depth,
            dir = is_dir(path .. name),
            open = false, -- only relevant when its a dir
            icon = true
        }
    end

    return sort_dirs(tree)
end


local function init_tree()
    Tree = create_nodes(ROOT_PATH, 0, list_dirs())
    if ROOT_PATH ~= '/' then
        table.insert(Tree, 1, {
            path = ROOT_PATH,
            name = '..',
            depth = 0,
            dir = true,
            open = false,
            icon = false
        })
    end
end

init_tree()

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

local function update_view(update_cursor)
    local buf = get_buf();
    if not buf then return end

    local cursor = api.nvim_win_get_cursor(0)

    api.nvim_buf_set_option(buf, 'modifiable', true)
    api.nvim_buf_set_lines(buf, 0, -1, false, format(Tree))
    highlight(buf, Tree)
    api.nvim_buf_set_option(buf, 'modifiable', false)

    if update_cursor == true then
        api.nvim_win_set_cursor(0, cursor)
    end
end

local function is_win_open()
    return get_buf() ~= nil
end

local function open_file(open_type)
    local tree_index = api.nvim_win_get_cursor(0)[1]
    local node = Tree[tree_index]

    if node.name == '..' then
        api.nvim_command('cd ..')
        if vim.loop.cwd() == '/' then
            ROOT_PATH = '/'
        else
            ROOT_PATH = vim.loop.cwd() .. '/'
        end
        init_tree()
        update_view()
    elseif open_type == 'chdir' then
        if node.dir == false or check_dir_access(node.path .. node.name) == false then return end
        api.nvim_command('cd ' .. node.path .. node.name)
        ROOT_PATH = vim.loop.cwd() .. '/'
        init_tree()
        update_view()
    elseif node.dir == true then
        local index = tree_index + 1;
        node.open = not node.open
        local next_node = Tree[index]
        if next_node ~= nil and next_node.depth > node.depth then
            while next_node ~= nil and next_node.depth ~= node.depth do
                table.remove(Tree, index)
                next_node = Tree[index]
            end
        else
            local dirlist = list_dirs(node.path .. node.name)
            local child_dirs = create_nodes(node.path .. node.name .. '/', node.depth + 1, dirlist)
            for i, n in pairs(child_dirs) do
                table.insert(Tree, tree_index + i, n)
            end
        end

        update_view(true)
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
            lib_file.edit_add(node.path .. node.name .. '/')
        else
            lib_file.edit_add(node.path)
        end
    elseif edit_type == 'delete' then
        lib_file.edit_remove(node.name, node.path, node.dir)
    elseif edit_type == 'rename' then
        lib_file.edit_rename(node.name, node.path, node.dir)
    end
end

return {
    toggle = toggle;
    open_file = open_file;
    edit_file = edit_file;
}

