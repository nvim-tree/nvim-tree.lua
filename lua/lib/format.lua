local api = vim.api

local function get_padding(depth)
    local str = ""

    while 0 < depth do
        str = str .. "  "
        depth = depth - 1
    end

    return str
end

local function default_icons(_, isdir, open)
    if isdir == true then
        if open == true then return " " end
        return " "
    end

    return ""
end

local function dev_icons(pathname, isdir, open)
    if isdir == true then return default_icons(pathname, isdir, open) end

    return api.nvim_call_function('WebDevIconsGetFileTypeSymbol', { pathname, isdir }) .. " "
end

local function get_icon_func_gen()
    if api.nvim_call_function('exists', { "WebDevIconsGetFileTypeSymbol" }) == 0 then
        return dev_icons
    else
        return default_icons
    end
end

local get_icon = get_icon_func_gen()

local function format_tree(tree)
    local dirs = {}

    for i, node in pairs(tree) do
        local padding = get_padding(node.depth)
        local icon = ""
        if node.icon == true then
            icon = get_icon(node.path .. node.name, node.dir, node.open)
        end
        dirs[i] = padding ..  icon .. node.name
    end

    return dirs
end

return {
    format_tree = format_tree;
}
