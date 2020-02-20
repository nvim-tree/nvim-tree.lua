local api = vim.api
local system = function(v) api.nvim_call_function('system', { v }) end
local update_view = require 'lib/winutils'.update_view
local refresh_tree = require 'lib/state'.refresh_tree
local refresh_git = require 'lib/git'.refresh_git

local rm = require 'lib/fs'.rm
local rename = require 'lib/fs'.rename

local input = function(v)
    local param
    if type(v) == 'string' then param = { v } else param = v end
    return api.nvim_call_function('input', param)
end

local function create_file(path)
    -- TODO: create files dynamically
    local new_file = input("Create file: " .. path)
    local new_path = path .. new_file
    if string.match(new_file, '.*/$') then
        system('mkdir -p ' .. new_path)
    else
        system('touch ' .. new_path)
    end
    refresh_git()
    refresh_tree()
    update_view()
end

local function remove_file(filename, path)
    local confirm = input("Remove " .. filename .. " ? y/n: ")
    if string.match(confirm, 'y.*$') ~= nil then
        rm(path .. filename)
        refresh_git()
        refresh_tree()
        update_view()
    end
end

local function rename_file(filename, path)
    local new_path = input({"Rename file " .. filename .. " : ", path .. filename})
    rename(path .. filename, new_path)
    refresh_git()
    refresh_tree()
    update_view()
end

return {
    create_file = create_file;
    remove_file = remove_file;
    rename_file = rename_file;
}
