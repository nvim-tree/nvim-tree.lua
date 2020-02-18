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

local function create_matcher(arr)
    return function(name)
        for _, n in pairs(arr) do
            if string.match(name, n) then return true end
        end
        return false
    end
end

local is_special = create_matcher({
    'README',
    'readme',
    'Makefile',
    'Cargo%.toml',
})

local is_pic = create_matcher({
    '%.jpe?g$',
    '%.png',
    '%.gif'
})

local function is_executable(name)
    return api.nvim_call_function('executable', { name }) == 1
end

local function dev_icons(pathname, isdir, open)
    if isdir == true or is_special(pathname) == true or is_executable(pathname) == true or is_pic(pathname) == true then
        return default_icons(pathname, isdir, open)
    end

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
}

local function highlight_git(highlight, node, line, col_start)
    if node.git ~= '' then
        highlight('LuaTreeGit'..node.git, line, col_start, -1)
        return true
    end

    return false
end

local function highlight_line(buffer)
    local function highlight(group, line, from, to)
        vim.api.nvim_buf_add_highlight(buffer, -1, group, line, from, to)
    end
    return function(line, node)
        local text_start = node.depth * 2
        if node.dir then
            if node.name ~= '..' then
                highlight('LuaTreeFolderIcon', line, 0, text_start + 4)

                if highlight_git(highlight, node, line, text_start + 4) == false then
                    highlight('LuaTreeFolderName', line, text_start + 4, -1)
                end
            else
                highlight('LuaTreeFolderName', line, 0, -1)
            end
            return
        elseif is_special(node.name) == true then
            highlight('LuaTreeSpecialFile', line, text_start, -1)
        elseif is_executable(node.path .. node.name) then
            highlight('LuaTreeExecFile', line, text_start, -1)
        elseif is_pic(node.path .. node.name) then
            highlight('LuaTreeImageFile', line, text_start, -1)
        else
            for k, v in pairs(HIGHLIGHT_GROUPS) do
                if string.match(node.name, k) ~= nil then
                    highlight('LuaTree' .. v, line, 0, text_start + 4)
                    highlight_git(highlight, node, line, text_start + 4)
                    return
                end
            end
        end
        highlight_git(highlight, node, line, text_start)
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
