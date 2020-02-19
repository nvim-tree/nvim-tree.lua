local api = vim.api
local function syslist(v) return api.nvim_call_function('systemlist', { v }) end
local get_git_attr = require 'lib/git'.get_git_attr

local function get_cwd() return vim.loop.cwd() end
local ROOT_PATH = get_cwd() .. '/'

local function set_root_path(path)
    ROOT_PATH = path
end

local Tree = {}

local function is_dir(path)
    local stat = vim.loop.fs_lstat(path)
    return stat and stat.type == 'directory' or false
end

local function is_symlink(path)
    local stat = vim.loop.fs_lstat(path)
    return stat and stat.type == 'link' or false
end

local function link_to(path)
    return vim.loop.fs_readlink(path) or ''
end

local function check_dir_access(path)
    return vim.loop.fs_access(path, 'R') == true
end

local function list_dirs(path)
    if check_dir_access(path) == false then
        -- TODO: display an error here (permission denied)
        return {}
    else
        local ls_cmd = 'ls -A --ignore=.git ' ..path
        return syslist(ls_cmd)
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

local function create_nodes(path, relpath, depth, dirs)
    local tree = {}

    if not string.find(path, '^.*/$') then path = path .. '/' end
    if not string.find(relpath, '^.*/$') and depth > 0 then relpath = relpath .. '/' end

    for i, name in pairs(dirs) do
        local full_path = path..name
        local dir = is_dir(full_path)
        local link = is_symlink(full_path)
        local linkto = link == true and link_to(full_path) or nil
        local rel_path = relpath ..name
        tree[i] = {
            path = path,
            relpath = rel_path,
            link = link,
            linkto = linkto,
            name = name,
            depth = depth,
            dir = dir,
            open = false,
            icon = true,
            git = get_git_attr(rel_path, dir)
        }
    end

    return sort_dirs(tree)
end

local function init_tree()
    Tree = create_nodes(ROOT_PATH, '', 0, list_dirs(ROOT_PATH))
    if ROOT_PATH ~= '/' then
        table.insert(Tree, 1, {
            path = ROOT_PATH,
            name = '..',
            depth = 0,
            dir = true,
            open = false,
            icon = false,
            git = ''
        })
    end
end

local function refresh_tree()
    local cache = {}

    for _, v in pairs(Tree) do
        if v.dir == true and v.open == true then
            table.insert(cache, v.path .. v.name)
        end
    end

    init_tree()

    for i, node in pairs(Tree) do
        if node.dir == true then
            for _, path in pairs(cache) do
                if node.path .. node.name == path then
                    node.open = true
                    local dirs = list_dirs(path)
                    for j, n in pairs(create_nodes(path, node.relpath, node.depth + 1, dirs)) do
                        table.insert(Tree, i + j, n)
                    end
                end
            end
        end
    end
end

local function open_dir(tree_index)
    local node = Tree[tree_index];
    node.open = not node.open

    if node.open == false then
        local next_index = tree_index + 1;
        local next_node = Tree[next_index]

        while next_node ~= nil and next_node.depth > node.depth do
            table.remove(Tree, next_index)
            next_node = Tree[next_index]
        end
    else
        local dirlist = list_dirs(node.path .. node.name)
        local child_dirs = create_nodes(node.path .. node.name .. '/', node.relpath, node.depth + 1, dirlist)

        for i, n in pairs(child_dirs) do
            table.insert(Tree, tree_index + i, n)
        end
    end
end

local function get_tree()
    return Tree
end

return {
    init_tree = init_tree;
    get_tree = get_tree;
    refresh_tree = refresh_tree;
    open_dir = open_dir;
    check_dir_access = check_dir_access;
    is_dir = is_dir;
    set_root_path = set_root_path;
    get_cwd = get_cwd;
}
