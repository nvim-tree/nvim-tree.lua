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

    local icon = api.nvim_call_function('WebDevIconsGetFileTypeSymbol', { pathname, isdir })
    if icon == "" then return "" end
    return icon  .. " "
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

local HIGHLIGHT_GROUPS = {
    ['^.*%.md$'] = 'MarkdownFile';
    ['^LICENSE$'] = 'LicenseFile';
    ['^.*%.vim$'] = 'VimFile';
    ['^.*%.c$'] = 'CFile';
    ['^.*%.cpp$'] = 'CFile';
    ['^.*%.cxx$'] = 'CFile';
    ['^.*%.h$'] = 'CFile';
    ['^.*%.hpp$'] = 'CFile';
    ['^.*%.py$'] = 'PythonFile';
    ['^.*%.lua$'] = 'LuaFile';
    ['^.*%.rs$'] = 'RustFile';
    ['^.*%.sh$'] = 'ShellFile';
    ['^.*%.zsh$'] = 'ShellFile';
    ['^.*%.csh$'] = 'ShellFile';
    ['^.*%.rs$'] = 'RustFile';
    ['^.*%.js$'] = 'JavascriptFile';
    ['^.*%.json$'] = 'JsonFile';
    ['^.*%.toml$'] = 'TomlFile';
    ['^.*%.yml$'] = 'YamlFile';
    ['^.*%.gitignore$'] = 'GitignoreFile';
    ['^.*%.ts$'] = 'TypescriptFile';
    ['^.*%.jsx$'] = 'ReactFile';
    ['^.*%.tsx$'] = 'ReactFile';
    ['^.*%.html?$'] = 'HtmlFile';
    ['^.*%.png$'] = 'ImageFile';
    ['^.*%.jpe?g$'] = 'ImageFile';
}

local function highlight_line(buffer)
    local function highlight(group, line, from, to)
        vim.api.nvim_buf_add_highlight(buffer, -1, group, line, from, to)
    end
    return function(line, node)
        local text_start = node.depth * 2 + 4
        if node.dir then
            if node.name ~= '..' then
                highlight('LuaTreeFolderIcon', line, 0, text_start)
                highlight('LuaTreeFolderName', line, text_start, -1)
            else
                highlight('LuaTreeFolderName', line, 0, -1)
            end
        else
            for k, v in pairs(HIGHLIGHT_GROUPS) do
                if string.match(node.name, k) ~= nil then
                    highlight('LuaTree' .. v, line, 0, text_start)
                    break
                end
            end
        end
    end
end

local function highlight_buffer(buffer, tree)
    local highlight = highlight_line(buffer)
    for i, node in pairs(tree) do
        highlight(i - 1, node)
    end
end

return {
    format_tree = format_tree;
    highlight_buffer = highlight_buffer;
}
