local function system(v) return vim.api.nvim_call_function('system', { v }) end

local function is_git_repo()
    local is_git = system('git rev-parse')
    return string.match(is_git, 'fatal') == nil
end

local GIT_CMD = 'git status --porcelain=v1 '

local function is_folder_dirty(path)
    local ret = system(GIT_CMD..path)
    return ret ~= nil and ret ~= ''
end

local function create_git_checker(pattern)
    return function(path)
        local ret = system(GIT_CMD..path)
        return string.match(ret, pattern) ~= nil
    end
end

local is_modified = create_git_checker('^ ?MM?')
local is_staged = create_git_checker('^ ?A')
local is_unmerged = create_git_checker('^ ?UU')
local is_untracked = create_git_checker('^%?%?')

local function get_git_attr(path, is_dir)
    if is_git_repo() == false then return '' end
    if is_dir then
        if is_folder_dirty(path) == true then return 'Dirty' end
    else
        if is_modified(path) then return 'Modified'
        elseif is_staged(path) then return 'Staged'
        elseif is_unmerged(path) then return 'Unmerged'
        elseif is_untracked(path) then return 'Untracked'
        end
    end

    return ''
end

return {
    get_git_attr = get_git_attr;
}
