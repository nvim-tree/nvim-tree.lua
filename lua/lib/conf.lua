local BUF_NAME = 'LuaTree'
local function get_cwd() return vim.loop.cwd() end
local ROOT_PATH = get_cwd() .. '/'

local function get_buf_name()
    return BUF_NAME
end

local function get_root_path()
    return ROOT_PATH
end

local function set_root_path(path)
    ROOT_PATH = path
end

return {
    get_buf_name = get_buf_name;
    get_root_path = get_root_path;
    set_root_path = set_root_path;
    get_cwd = get_cwd;
}

