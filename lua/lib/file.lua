local api = vim.api
local system = function(v) api.nvim_call_function('system', { v }) end
local update_tree_view = require 'lib/winutils'.update_view
local scratch_wrapper = require 'lib/winutils'.scratch_wrapper
local update_tree_state = require 'lib/state'.refresh_tree
local refresh_git = require 'lib/git'.refresh_git

local EDIT_FILE = nil

local function edit_add(path)
    scratch_wrapper("add", { "Create File", path })
end

local function edit_remove(filename, path)
    EDIT_FILE = path .. filename
    scratch_wrapper("delete", { "Remove " .. filename .. " ?",  "y/n: " })
end

local function edit_rename(filename, path)
    EDIT_FILE = path .. filename
    scratch_wrapper("rename", { "Rename " .. path, path .. filename })
end

local function add_file(path)
    if string.match(path, '.*/$') then
        system('mkdir -p ' .. path)
        refresh_git()
        update_tree_state()
        update_tree_view(true)
    else
        system('touch ' .. path)
        refresh_git()
        update_tree_state()
        update_tree_view(true)
    end
    api.nvim_command("q!")
end

local function remove_file(confirmation)
    if string.match(confirmation, '^y/n: y.*$') ~= nil then
        system('rm -rf ' .. EDIT_FILE)
        refresh_git()
        update_tree_state()
        update_tree_view(true)
    end
    EDIT_FILE = nil
    api.nvim_command("q!")
end

local function rename_file(path)
    system('mv '..EDIT_FILE..' '..path)
    EDIT_FILE = nil
    api.nvim_command("q!")
    refresh_git()
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
