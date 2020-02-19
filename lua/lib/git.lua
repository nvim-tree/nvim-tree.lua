local function system(v) return vim.api.nvim_call_function('system', { v }) end

local function is_git_repo()
    local is_git = system('git rev-parse')
    return string.match(is_git, 'fatal') == nil
end

local IS_GIT_REPO = is_git_repo()

local function set_git_status()
    if IS_GIT_REPO == false then return '' end
    return system('git status --porcelain=v1')
end

local GIT_STATUS = set_git_status()

local function refresh_git()
    IS_GIT_REPO = is_git_repo()
    GIT_STATUS = set_git_status()
end

local function is_folder_dirty(relpath)
    return string.match(GIT_STATUS, relpath) ~= nil
end

local function create_git_checker(pattern)
    return function(relpath)
        local ret = string.match(GIT_STATUS, '^.*' .. relpath)
        if ret == nil then return false end
        return string.match(ret, pattern) ~= nil
    end
end

local is_modified = create_git_checker('^ ?MM?')
local is_staged = create_git_checker('^ ?A')
local is_unmerged = create_git_checker('^ ?UU')
local is_untracked = create_git_checker('^%?%?')

local function get_git_attr(path, is_dir)
    if IS_GIT_REPO == false then return '' end
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
    refresh_git = refresh_git;
}
