local api = vim.api
local luv = vim.loop

local function get_cwd() return luv.cwd() end

local function is_dir(path)
    local stat = luv.fs_lstat(path)
    return stat and stat.type == 'directory' or false
end

local function is_symlink(path)
    local stat = luv.fs_lstat(path)
    return stat and stat.type == 'link' or false
end

local function link_to(path)
    return luv.fs_readlink(path) or ''
end

local function check_dir_access(path)
    if luv.fs_access(path, 'R') == true then
        return true
    else
        api.nvim_err_writeln('Permission denied: ' .. path)
        return false
    end
end

local function rm(path)
    local stat = luv.fs_lstat(path)
    if stat and stat.type == 'directory' then
        return luv.fs_rmdir(path)
    else
        return luv.fs_unlink(path)
    end
end

local function rename(file, new_path)
    luv.fs_rename(file, new_path, function(err)
        if err ~= nil then
            -- TODO: display error somehow.
            -- it wont work with vim.api
        end
    end)
end

return {
    check_dir_access = check_dir_access;
    is_symlink = is_symlink;
    link_to = link_to;
    get_cwd = get_cwd;
    is_dir = is_dir;
    rename = rename;
    rm = rm;
}
