local api = vim.api

local update_view = require 'lib/winutils'.update_view
local refresh_tree = require 'lib/state'.refresh_tree
local refresh_git = require 'lib/git'.refresh_git
local utils = require'lib/utils'

local fs = require 'lib/fs'
local rm = fs.rm
local rename = fs.rename
local create = fs.create

local function input(v)
    local param
    if type(v) == 'string' then param = { v } else param = v end
    return api.nvim_call_function('input', param)
end

local function clear_prompt()
    api.nvim_command('normal :<esc>')
end

local function create_file(path)
    local new_file = input("Create file: " .. path)

    local file = nil
    if not new_file:match('.*/$') then
        file = new_file:reverse():gsub('/.*$', ''):reverse()
        new_file = new_file:gsub('[^/]*$', '')
    end

    local folders = ""
    if #new_file ~= 0 then
        for p in new_file:gmatch('[^/]*') do
            if p and p ~= "" then
                folders = folders .. p .. '/'
            end
        end
    end

    clear_prompt()
    create(path, file, folders)
    refresh_git()
    refresh_tree()
    update_view()
end

local function remove_file(filename, path)
    local ans = input("Remove " .. filename .. " ? y/n: ")
    clear_prompt()
    if ans == "y" then
        rm(path .. filename)
        refresh_git()
        refresh_tree()
        update_view()
    end
end

local function rename_file(filename, path)
    local new_path = input({"Rename file " .. filename .. ": ", path .. filename})
    clear_prompt()
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
