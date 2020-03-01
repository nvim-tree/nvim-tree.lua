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

local function print_err(err)
    if err ~= nil then
        api.nvim_command('echohl ErrorMsg')
        -- remove the \n with string.sub
        api.nvim_command('echomsg "'..string.sub(err, 0, -2)..'"')
        api.nvim_command('echohl None')
    end
end

local function system(v)
    print_err(api.nvim_call_function('system', { v }))
end

local function check_dir_access(path)
    if luv.fs_access(path, 'R') == true then
        return true
    else
        print_err('Permission denied: ' .. path)
        return false
    end
end

-- TODO: better handling of path removal, rename and file creation with luv calls
-- it will take some time so leave it for a dedicated PR
local function rm(path)
    system('rm -rf ' ..path)
end

local function rename(file, new_path)
    system('mv '..file..' '..new_path)
end

local function create(path, file, folders)
    if folders ~= "" then system('mkdir -p '..folders) end
    if file ~= nil then system('touch '..path..folders..file) end
end

return {
    check_dir_access = check_dir_access;
    is_symlink = is_symlink;
    link_to = link_to;
    get_cwd = get_cwd;
    is_dir = is_dir;
    rename = rename;
    rm = rm;
    create = create;
}
