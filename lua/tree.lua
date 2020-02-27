local api = vim.api

local fs_update = require 'lib/fs_update'
local create_file = fs_update.create_file
local rename_file = fs_update.rename_file
local remove_file = fs_update.remove_file

local fs = require 'lib/fs'
local check_dir_access = fs.check_dir_access
local is_dir = fs.is_dir
local get_cwd = fs.get_cwd

local state = require 'lib/state'
local get_tree = state.get_tree
local init_tree = state.init_tree
local open_dir = state.open_dir
local refresh_tree = state.refresh_tree
local set_root_path = state.set_root_path

local winutils = require 'lib/winutils'
local update_view = winutils.update_view
local is_win_open = winutils.is_win_open
local close = winutils.close
local open = winutils.open
local set_mappings = winutils.set_mappings
local replace_tree = winutils.replace_tree

local git = require 'lib/git'
local refresh_git = git.refresh_git
local force_refresh_git = git.force_refresh_git

require 'lib/colors'.init_colors()

init_tree()

local function toggle()
    if is_win_open() == true then
        close()
    else
        open()
        update_view()
        set_mappings()
    end
end

local function open_file(open_type)
    local tree_index = api.nvim_win_get_cursor(0)[1]
    local tree = get_tree()
    local node = tree[tree_index]

    if node.name == '..' then
        api.nvim_command('cd ..')

        local new_path = get_cwd()
        if new_path ~= '/' then
            new_path = new_path .. '/'
        end

        set_root_path(new_path)
        force_refresh_git()
        init_tree(new_path)
        update_view()

    elseif open_type == 'chdir' then
        if node.dir == false or check_dir_access(node.path .. node.name) == false then return end

        api.nvim_command('cd ' .. node.path .. node.name)
        local new_path = get_cwd() .. '/'
        set_root_path(new_path)
        force_refresh_git()
        init_tree(new_path)
        update_view()

    elseif node.link == true then
        local link_to_dir = is_dir(node.linkto)
        if link_to_dir == true and check_dir_access(node.linkto) == false then return end

        if link_to_dir == true then
            api.nvim_command('cd ' .. node.linkto)
            local new_path = get_cwd() .. '/'
            set_root_path(new_path)
            force_refresh_git()
            init_tree(new_path)
            update_view()
        else
            api.nvim_command('wincmd l | '..open_type..' '.. node.linkto)
        end

    elseif node.dir == true then
        if check_dir_access(node.path .. node.name) == false then return end
        open_dir(tree_index)
        update_view(true)

    else
        api.nvim_command('wincmd l | '..open_type..' '.. node.path .. node.name)
    end
end

local function edit_file(edit_type)
    local tree = get_tree()
    local tree_index = api.nvim_win_get_cursor(0)[1]
    local node = tree[tree_index]

    if edit_type == 'create' then
        if node.dir == true then
            create_file(node.path .. node.name .. '/')
        else
            create_file(node.path)
        end
    elseif edit_type == 'remove' then
        remove_file(node.name, node.path)
    elseif edit_type == 'rename' then
        rename_file(node.name, node.path)
    end
end

local function refresh()
    if refresh_git() == true then
        refresh_tree()
        update_view()
    end
end

local function check_windows_and_close()
    local wins = api.nvim_list_wins()

    if #wins == 1 and is_win_open() then
        api.nvim_command('q!')
    end
end

local function check_buffer_and_open()
    local bufname = api.nvim_buf_get_name(0)
    if bufname == '' then
        toggle()
    elseif is_dir(bufname) then
        api.nvim_command('cd ' .. bufname)

        local new_path = get_cwd()
        if new_path ~= '/' then
            new_path = new_path .. '/'
        end
        set_root_path(new_path)
        init_tree()

        toggle()
    end
end

return {
    toggle = toggle;
    open_file = open_file;
    edit_file = edit_file;
    refresh = refresh;
    check_windows_and_close = check_windows_and_close;
    check_buffer_and_open = check_buffer_and_open;
    replace_tree = replace_tree;
}

