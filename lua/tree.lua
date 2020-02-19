local api = vim.api

local lib_file = require 'lib/file'
local edit_add = lib_file.edit_add
local edit_remove = lib_file.edit_remove
local edit_rename = lib_file.edit_rename

local stateutils = require 'lib/state'
local get_tree = stateutils.get_tree
local init_tree = stateutils.init_tree
local open_dir = stateutils.open_dir
local check_dir_access = stateutils.check_dir_access
local refresh_tree = stateutils.refresh_tree
local is_dir = stateutils.is_dir
local set_root_path = stateutils.set_root_path
local get_cwd = stateutils.get_cwd

local winutils = require 'lib/winutils'
local update_view = winutils.update_view
local is_win_open = winutils.is_win_open
local close = winutils.close
local open = winutils.open
local set_mappings = winutils.set_mappings

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

        local new_path
        if get_cwd() == '/' then
            new_path = '/'
        else
            new_path = get_cwd() .. '/'
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

    if edit_type == 'add' then
        if node.dir == true then
            edit_add(node.path .. node.name .. '/')
        else
            edit_add(node.path)
        end
    elseif edit_type == 'remove' then
        edit_remove(node.name, node.path, node.dir)
    elseif edit_type == 'rename' then
        edit_rename(node.name, node.path, node.dir)
    end
end

local function refresh()
    if refresh_git() == true then
        refresh_tree()
        update_view()
    end
end

return {
    toggle = toggle;
    open_file = open_file;
    edit_file = edit_file;
    refresh = refresh;
}

